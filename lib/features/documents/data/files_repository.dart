import '../../../core/errors/errors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../auth/data/auth_repository.dart';

/// Response model for POST /files/init and GET /files/download.
class FileUrlResponse {
  const FileUrlResponse({required this.url, required this.key});

  final String url;
  final String key;

  factory FileUrlResponse.fromJson(Map<String, dynamic> json) {
    return FileUrlResponse(
      url: json['url'] as String,
      key: json['key'] as String,
    );
  }
}

/// Repository for the Files API.
///
/// Handles presigned S3 URLs for upload/download and file deletion.
///
/// Upload flow:
///   1. `POST /files/init` → get presigned upload URL and key
///   2. PUT file bytes to the returned URL (outside this repo)
///   3. Use the returned `key` in `/drivers/documents` etc.
class FilesRepository {
  FilesRepository({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  }) : _apiClient = apiClient ??
            ApiClient(
              authInterceptor: authRepository != null
                  ? AuthInterceptor(authRepository: authRepository)
                  : null,
            );

  final ApiClient _apiClient;

  /// Request a presigned S3 upload URL.
  ///
  /// POST /files/init
  /// Body: { fileName, mimeType, size, purpose, checksum }
  /// Returns: { url, key } — PUT file bytes directly to `url`.
  ///
  /// [purpose] must be one of: PROFILE_PHOTO | DRIVER_LICENSE |
  /// VEHICLE_REGISTRATION | OTHER
  Future<Result<FileUrlResponse>> initUpload({
    required String fileName,
    required String mimeType,
    required int size,
    required String purpose,
    required String checksum,
  }) async {
    return _safeCall(() async {
      final response = await _apiClient.postJson(
        '/files/init',
        body: {
          'fileName': fileName,
          'mimeType': mimeType,
          'size': size,
          'purpose': purpose,
          'checksum': checksum,
        },
      );
      return FileUrlResponse.fromJson(response);
    });
  }

  /// Request a presigned S3 download URL.
  ///
  /// GET /files/download?key=`<key>`
  /// Returns: { url, key }
  Future<Result<FileUrlResponse>> getDownloadUrl({
    required String key,
  }) async {
    return _safeCall(() async {
      final response = await _apiClient.getJsonWithParams(
        '/files/download',
        queryParams: {'key': key},
      );
      return FileUrlResponse.fromJson(response);
    });
  }

  /// Soft-delete a file.
  ///
  /// DELETE /files/:key
  Future<Result<void>> deleteFile({required String key}) async {
    return _safeCall(() async {
      await _apiClient.deleteJson('/files/$key');
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
