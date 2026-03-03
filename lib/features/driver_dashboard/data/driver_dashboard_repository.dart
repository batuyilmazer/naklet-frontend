import '../../../core/models/driver/driver.dart';
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
  }) : _apiClient = apiClient ??
            ApiClient(
              authInterceptor: authRepository != null
                  ? AuthInterceptor(authRepository: authRepository)
                  : null,
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
    return Driver.fromJson(driverData);
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
      body['licenseChecksum'] = licenseChecksum;
    }
    if (registrationKey != null) {
      body['registrationKey'] = registrationKey;
      body['registrationChecksum'] = registrationChecksum;
    }
    await _apiClient.patchJson('/drivers/documents', body: body);
  }
}
