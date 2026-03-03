import 'package:flutter/foundation.dart';

import '../../../core/models/driver/driver.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/driver/vehicle.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../features/auth/data/auth_repository.dart';

/// Repository for driver dashboard operations.
///
/// Handles vehicle management and driver profile endpoints.
class DriverDashboardRepository {
  DriverDashboardRepository({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             authInterceptor: AuthInterceptor(
               authRepository: authRepository ?? AuthRepository(),
             ),
           );

  final ApiClient _apiClient;

  /// Get current driver's full profile with vehicles.
  ///
  /// GET /drivers/me — returns driver status, rejectionReason, and vehicles.
  Future<Driver> getDriverProfile() async {
    final response = await _apiClient.getJson('/drivers/me');
    final driverData = response['driver'] as Map<String, dynamic>?;
    if (driverData == null) {
      throw Exception('Driver data not found in response');
    }
    final driver = Driver.fromJson(driverData);

    try {
      final profileResponse = await _apiClient.getJson('/me/profile');
      final profile = profileResponse['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        return driver.copyWith(
          firstName: profile['firstName'] as String?,
          lastName: profile['lastName'] as String?,
          phoneNumber: profile['phoneNumber'] as String?,
        );
      }
    } catch (_) {
      // Personal profile data is optional for this screen.
    }

    return driver;
  }

  /// Add a new vehicle to the driver's fleet.
  ///
  /// POST /drivers/vehicles
  Future<Vehicle> addVehicle({
    required String type,
    required String plateNumber,
    required int capacityKg,
  }) async {
    final response = await _apiClient.postJson(
      '/drivers/vehicles',
      body: {
        'type': type,
        'plateNumber': plateNumber,
        'capacityKg': capacityKg,
      },
    );
    return Vehicle.fromJson(response);
  }

  /// Toggle vehicle active/inactive status.
  ///
  /// PATCH /drivers/vehicles/:vehicleId/active
  Future<void> toggleVehicleActive({
    required String vehicleId,
    required bool isActive,
  }) async {
    await _apiClient.patchJson(
      '/drivers/vehicles/$vehicleId/active',
      body: {'isActive': isActive},
    );
  }

  /// Upload driver documents.
  ///
  /// PATCH /drivers/documents
  Future<void> uploadDocuments({
    String? licenseKey,
    String? licenseChecksum,
    String? registrationKey,
    String? registrationChecksum,
  }) async {
    final body = <String, dynamic>{};
    if (licenseKey != null) {
      body['licenseKey'] = licenseKey;
      if (licenseChecksum != null) {
        body['licenseChecksum'] = licenseChecksum;
      }
    }
    if (registrationKey != null) {
      body['registrationKey'] = registrationKey;
      if (registrationChecksum != null) {
        body['registrationChecksum'] = registrationChecksum;
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[DriverDashboardRepository][Documents] PATCH /drivers/documents '
        'licenseKey=$licenseKey registrationKey=$registrationKey',
      );
    }
    try {
      await _apiClient.patchJson('/drivers/documents', body: body);
      if (kDebugMode) {
        debugPrint(
          '[DriverDashboardRepository][Documents] confirm response: success',
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[DriverDashboardRepository][Documents] ApiException '
          'status=${e.statusCode} message=${e.message} body=${e.responseBody}',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[DriverDashboardRepository][Documents] Exception type=${e.runtimeType} message=$e',
        );
      }
      rethrow;
    }
  }
}
