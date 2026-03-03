import '../../../core/errors/errors.dart';
import '../../../core/models/user/profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../auth/data/auth_repository.dart';

/// Repository for user profile endpoints under /me.
///
/// Handles:
/// - GET  /me/profile       — fetch current user profile (404 if not yet created)
/// - PATCH /me/profile      — create or update profile fields
/// - POST /me/profile-photo — confirm profile photo upload
class ProfileRepository {
  ProfileRepository({ApiClient? apiClient, AuthRepository? authRepository})
    : _apiClient =
          apiClient ??
          ApiClient(
            authInterceptor: AuthInterceptor(
              authRepository: authRepository ?? AuthRepository(),
            ),
          );

  final ApiClient _apiClient;

  /// Fetch the current user's profile.
  ///
  /// GET /me/profile
  /// Returns null (404) if the profile has not been created yet.
  Future<Result<Profile?>> getProfile() async {
    return _safeCall<Profile?>(() async {
      try {
        final response = await _apiClient.getJson('/me/profile');
        final profileData = response['profile'] as Map<String, dynamic>?;
        if (profileData == null) return null;
        return Profile.fromJson(profileData);
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
  Future<Result<Profile>> updateProfile({
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
      return Profile.fromJson(profileData);
    });
  }

  /// Confirm profile photo upload.
  ///
  /// POST /me/profile-photo
  /// After uploading the file via the presigned URL from `/files/init`,
  /// call this to confirm and attach it to the profile.
  Future<Result<void>> confirmProfilePhoto({
    required String key,
    String? checksum,
  }) async {
    return _safeCall(() async {
      await _apiClient.postJson(
        '/me/profile-photo',
        body: {'key': key, if (checksum != null) 'checksum': checksum},
      );
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
