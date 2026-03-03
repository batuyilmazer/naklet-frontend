/// Profile model aligned with backend Prisma schema.
/// Backend returns: { id, firstName, lastName, phoneNumber, userId, createdAt, updatedAt }

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
