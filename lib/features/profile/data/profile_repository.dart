import '../../../core/errors/errors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../auth/data/auth_repository.dart';

/// Model for GET /me/profile and PATCH /me/profile response.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : '';
  }
}

/// Repository for user profile endpoints under /me.
///
/// Handles:
/// - GET  /me/profile   — fetch current user profile (404 if not yet created)
/// - PATCH /me/profile  — create or update profile fields
class ProfileRepository {
  ProfileRepository({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  }) : _apiClient = apiClient ??
            ApiClient(
              authInterceptor: authRepository != null
                  ? AuthInterceptor(authRepository: authRepository)
                  : null,
            );

  final ApiClient _apiClient;

  /// Fetch the current user's profile.
  ///
  /// GET /me/profile
  /// Returns null (404) if the profile has not been created yet.
  Future<Result<UserProfile?>> getProfile() async {
    return _safeCall<UserProfile?>(() async {
      try {
        final response = await _apiClient.getJson('/me/profile');
        final profileData = response['profile'] as Map<String, dynamic>?;
        if (profileData == null) return null;
        return UserProfile.fromJson(profileData);
      } on ApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  /// Create or update the current user's profile.
  ///
  /// PATCH /me/profile
  /// At least one field must be provided.
  Future<Result<UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    return _safeCall(() async {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

      final response = await _apiClient.patchJson('/me/profile', body: body);
      final profileData = response['profile'] as Map<String, dynamic>;
      return UserProfile.fromJson(profileData);
    });
  }

  Future<Result<T>> _safeCall<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return success<T>(data);
    } on ApiException catch (e) {
      return fail<T>(ErrorMapper.mapApiException(e));
    } catch (e) {
      return fail<T>(ErrorMapper.mapException(e));
    }
  }
}
