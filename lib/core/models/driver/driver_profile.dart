/// Driver profile model aligned with backend schema.
///
/// Contains personal information of the driver displayed in
/// search results and profile pages.
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String userId;

  /// Full display name.
  String get fullName => '$firstName $lastName';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'userId': userId,
  };
}
