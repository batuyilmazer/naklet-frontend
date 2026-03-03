import '../../../core/models/search/nearby_vehicle.dart';
import '../../../core/network/api_client.dart';

/// Repository for nearby vehicle search.
///
/// Calls `GET /search/nearby` which is a public endpoint (no auth required).
class SearchRepository {
  SearchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Search for nearby vehicles.
  ///
  /// Parameters:
  /// - `lat`: Latitude of the search center (required)
  /// - `lng`: Longitude of the search center (required)
  /// - `radius`: Search radius in meters (default: 15000, max: 50000)
  /// - `vehicleType`: Optional vehicle type filter
  Future<List<NearbyVehicle>> searchNearby({
    required double lat,
    required double lng,
    int radius = 15000,
    String? vehicleType,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
    };

    if (vehicleType != null) {
      queryParams['vehicleType'] = vehicleType;
    }

    final response = await _apiClient.getJsonWithParams(
      '/search/nearby',
      queryParams: queryParams,
    );

    final vehiclesList = response['vehicles'] as List<dynamic>? ?? [];
    return vehiclesList
        .map((v) => NearbyVehicle.fromJson(v as Map<String, dynamic>))
        .toList();
  }
}
