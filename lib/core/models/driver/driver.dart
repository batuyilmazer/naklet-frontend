import 'driver_status.dart';
import 'vehicle.dart';

/// Driver model aligned with `GET /drivers/me` response.
///
/// Backend returns: { driver: { id, status, rejectionReason, vehicles[] } }
class Driver {
  const Driver({
    required this.id,
    required this.status,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.rejectionReason,
    this.vehicles = const [],
  });

  final String id;
  final DriverStatus status;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? rejectionReason;
  final List<Vehicle> vehicles;

  /// Whether the driver is approved and visible in search results.
  bool get isApproved => status == DriverStatus.approved;

  /// Whether the driver is pending admin approval.
  bool get isPending => status == DriverStatus.pending;

  /// Whether the driver was rejected.
  bool get isRejected => status == DriverStatus.rejected;

  Driver copyWith({
    String? id,
    DriverStatus? status,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? rejectionReason,
    List<Vehicle>? vehicles,
  }) {
    return Driver(
      id: id ?? this.id,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      status: DriverStatus.fromString(json['status'] as String),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      vehicles: (json['vehicles'] as List<dynamic>?)
              ?.map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.apiValue,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
      };
}
