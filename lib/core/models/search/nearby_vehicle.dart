import '../driver/vehicle_type.dart';

/// Nearby driver info from search results.
class NearbyDriver {
  const NearbyDriver({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}

/// Nearby vehicle model from search results.
///
/// This is the response model for `GET /search/nearby`.
/// Contains vehicle info + driver summary + distance in meters.
class NearbyVehicle {
  const NearbyVehicle({
    required this.id,
    required this.type,
    required this.plateNumber,
    required this.capacityKg,
    required this.distance,
    required this.driver,
  });

  final String id;
  final VehicleType type;
  final String plateNumber;
  final int capacityKg;
  final double distance; // metres
  final NearbyDriver driver;

  /// Distance formatted for display (e.g. "2.3 km" or "500 m").
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  factory NearbyVehicle.fromJson(Map<String, dynamic> json) {
    return NearbyVehicle(
      id: json['id'] as String,
      type: VehicleType.fromString(json['type'] as String),
      plateNumber: json['plateNumber'] as String,
      capacityKg: (json['capacityKg'] as num).toInt(),
      distance: (json['distance'] as num).toDouble(),
      driver: NearbyDriver.fromJson(
        json['driver'] as Map<String, dynamic>,
      ),
    );
  }
}
