import 'vehicle_type.dart';

/// Vehicle model aligned with backend schema.
///
/// Each vehicle belongs to a driver and can be independently activated/deactivated.
/// Location is tracked per-vehicle (not per-driver).
class Vehicle {
  const Vehicle({
    required this.id,
    required this.type,
    required this.plateNumber,
    required this.capacityKg,
    this.isActive = false,
    this.lat,
    this.lng,
    required this.driverId,
  });

  final String id;
  final VehicleType type;
  final String plateNumber;
  final int capacityKg;
  final bool isActive;
  final double? lat;
  final double? lng;
  final String driverId;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      type: VehicleType.fromString(json['type'] as String),
      plateNumber: json['plateNumber'] as String,
      capacityKg: (json['capacityKg'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      driverId: json['driverId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.apiValue,
    'plateNumber': plateNumber,
    'capacityKg': capacityKg,
    'isActive': isActive,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    'driverId': driverId,
  };

  Vehicle copyWith({
    String? id,
    VehicleType? type,
    String? plateNumber,
    int? capacityKg,
    bool? isActive,
    double? lat,
    double? lng,
    String? driverId,
  }) {
    return Vehicle(
      id: id ?? this.id,
      type: type ?? this.type,
      plateNumber: plateNumber ?? this.plateNumber,
      capacityKg: capacityKg ?? this.capacityKg,
      isActive: isActive ?? this.isActive,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      driverId: driverId ?? this.driverId,
    );
  }
}
