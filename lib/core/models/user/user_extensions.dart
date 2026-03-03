import 'user.dart';

/// Computed properties and utility methods for [User].
extension UserStatusExtension on User {
  /// User should be prompted to verify email.
  bool get needsEmailVerification => !emailVerified;
}
