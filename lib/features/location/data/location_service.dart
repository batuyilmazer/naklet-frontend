import 'package:flutter/foundation.dart';

/// Location service for GPS-based operations.
///
/// Handles device location retrieval and permission management.
/// In Phase 4, this will integrate with the `geolocator` package.
/// Currently provides mock/fallback coordinates.
class LocationService {
  /// Get current device location.
  ///
  /// Returns a tuple of (latitude, longitude) or null if unavailable.
  Future<({double lat, double lng})?> getCurrentLocation() async {
    // TODO: Integrate with geolocator package in Phase 4.
    // For now, return Istanbul center as default.
    if (kDebugMode) {
      debugPrint('LocationService: Using default Istanbul coordinates');
    }
    return (lat: 41.0082, lng: 28.9784);
  }

  /// Check if location permission is granted.
  Future<bool> isLocationPermissionGranted() async {
    // TODO: Integrate with geolocator package in Phase 4.
    return true;
  }

  /// Request location permission.
  Future<bool> requestLocationPermission() async {
    // TODO: Integrate with geolocator package in Phase 4.
    return true;
  }

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    // TODO: Integrate with geolocator package in Phase 4.
    return true;
  }
}
