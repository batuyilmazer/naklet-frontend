/// Base application-level exception.
abstract class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Generic network/API exception with optional HTTP status code.
class ApiException extends AppException {
  ApiException(
    super.message, {
    this.statusCode,
    this.errorCode,
    this.responseBody,
  });

  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? responseBody;
}

/// Thrown when authentication is required or has failed.
class AuthException extends AppException {
  AuthException(super.message);
}
