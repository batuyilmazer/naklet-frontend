import '../../../core/errors/errors.dart';
import '../../../core/models/user/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/storage/session_storage_impl.dart';


/// Response model for driver registration endpoint.
class DriverRegisterResponse {
  const DriverRegisterResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final String deviceId;

  factory DriverRegisterResponse.fromJson(Map<String, dynamic> json) {
    return DriverRegisterResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access'] as String,
      refreshToken: json['session'] != null
          ? (json['session'] as Map<String, dynamic>)['refreshToken'] as String
          : json['refreshToken'] as String,
      deviceId: json['session'] != null
          ? (json['session'] as Map<String, dynamic>)['deviceId'] as String
          : json['deviceId'] as String,
    );
  }
}

/// Repository for driver registration.
///
/// Handles POST /drivers/register which creates User + Profile + Driver + Vehicle
/// in a single transaction.
class DriverRegisterRepository {
  DriverRegisterRepository({
    ApiClient? apiClient,
    SessionStorage? sessionStorage,
  }) : _apiClient = apiClient ?? ApiClient(),
       _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  /// Register a new driver with profile and vehicle information.
  ///
  /// Returns `Result<User>` after saving tokens to session storage.
  Future<Result<User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required List<Map<String, dynamic>> vehicles,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/drivers/register',
        body: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'vehicles': vehicles,
        },
      );

      final registerResponse = DriverRegisterResponse.fromJson(response);

      // Save tokens and user info to session storage
      await _sessionStorage.saveSession(
        accessToken: registerResponse.accessToken,
        refreshToken: registerResponse.refreshToken,
        deviceId: registerResponse.deviceId,
        user: registerResponse.user,
      );

      return success<User>(registerResponse.user);
    } on ApiException catch (e) {
      return fail<User>(ErrorMapper.mapApiException(e));
    } catch (e) {
      return fail<User>(ErrorMapper.mapException(e));
    }
  }
}
