import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../features/auth/data/auth_repository.dart';

/// Repository for vehicle location updates (driver side).
///
/// Handles `POST /drivers/vehicles/:vehicleId/location` endpoint.
class VehicleLocationRepository {
  VehicleLocationRepository({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  }) : _apiClient = apiClient ??
            ApiClient(
              authInterceptor: authRepository != null
                  ? AuthInterceptor(authRepository: authRepository)
                  : null,
            );

  final ApiClient _apiClient;

  /// Update location for a specific vehicle.
  ///
  /// Sends current GPS coordinates to the backend.
  Future<void> updateVehicleLocation({
    required String vehicleId,
    required double lat,
    required double lng,
  }) async {
    await _apiClient.postJson(
      '/drivers/vehicles/$vehicleId/location',
      body: {'lat': lat, 'lng': lng},
    );
  }
}
