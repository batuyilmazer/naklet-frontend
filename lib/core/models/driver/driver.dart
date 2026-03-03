import 'driver_status.dart';
import 'vehicle.dart';

/// Driver model aligned with `GET /drivers/me` response.
///
/// Backend returns: { driver: { id, status, rejectionReason, vehicles[] } }
class Driver {
  const Driver({
    required this.id,
    required this.status,
    this.rejectionReason,
    this.vehicles = const [],
  });

  final String id;
  final DriverStatus status;
  final String? rejectionReason;
  final List<Vehicle> vehicles;

  /// Whether the driver is approved and visible in search results.
  bool get isApproved => status == DriverStatus.approved;

  /// Whether the driver is pending admin approval.
  bool get isPending => status == DriverStatus.pending;

  /// Whether the driver was rejected.
  bool get isRejected => status == DriverStatus.rejected;

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      status: DriverStatus.fromString(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      vehicles: (json['vehicles'] as List<dynamic>?)
              ?.map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
      };
}
