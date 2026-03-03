import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

/// Result of uploading binary data to a presigned URL.
class PresignedPutResult {
  const PresignedPutResult({required this.statusCode, this.etag});

  final int statusCode;
  final String? etag;
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
    http.Client? httpClient,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             authInterceptor: AuthInterceptor(
               authRepository: authRepository ?? AuthRepository(),
             ),
           ),
       _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _httpClient;

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
      _debugUploadLog(
        'initUpload request: fileName=$fileName, mimeType=$mimeType, '
        'size=$size, purpose=$purpose, checksumPrefix=${_checksumPrefix(checksum)}',
      );
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
      final fileUrl = FileUrlResponse.fromJson(response);
      final uri = Uri.tryParse(fileUrl.url);
      _debugUploadLog(
        'initUpload response: key=${fileUrl.key}, '
        'urlHost=${uri?.host ?? 'invalid'}, scheme=${uri?.scheme ?? 'invalid'}',
      );
      return fileUrl;
    });
  }

  /// Request a presigned S3 download URL.
  ///
  /// GET /files/download?key=`<key>`
  /// Returns: { url, key }
  Future<Result<FileUrlResponse>> getDownloadUrl({required String key}) async {
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
      final encodedKey = Uri.encodeComponent(key);
      await _apiClient.deleteJson('/files/$encodedKey');
    });
  }

  /// Upload file bytes to a presigned URL via HTTP PUT.
  Future<Result<PresignedPutResult>> uploadToPresignedUrl({
    required String url,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return _safeCall(() async {
      final uri = Uri.parse(url);
      _debugUploadLog(
        'presigned PUT start: host=${uri.host}, scheme=${uri.scheme}, '
        'path=${_pathTail(uri.path)}, mimeType=$mimeType, bytes=${bytes.length}',
      );
      final response = await _httpClient
          .put(uri, headers: {'Content-Type': mimeType}, body: bytes)
          .timeout(const Duration(seconds: 60));
      _debugUploadLog(
        'presigned PUT response: status=${response.statusCode}, '
        'etag=${response.headers['etag']}, requestId=${response.headers['x-amz-request-id']}, '
        'bucketRegion=${response.headers['x-amz-bucket-region']}, '
        'bodyPreview=${_preview(response.body)}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final isRegionRedirect =
            response.statusCode == 301 &&
            response.body.contains('PermanentRedirect');
        throw ApiException(
          isRegionRedirect
              ? 'Dosya yükleme endpointi geçersiz. Sunucuda S3 bölge ayarını kontrol edin.'
              : 'Dosya yükleme başarısız oldu.',
          statusCode: response.statusCode,
          responseBody: {
            'body': _preview(response.body),
            'headers': {
              'etag': response.headers['etag'],
              'x-amz-request-id': response.headers['x-amz-request-id'],
              'x-amz-id-2': response.headers['x-amz-id-2'],
              'x-amz-bucket-region': response.headers['x-amz-bucket-region'],
              'content-type': response.headers['content-type'],
            },
            'host': uri.host,
            'path': uri.path,
          },
        );
      }

      return PresignedPutResult(
        statusCode: response.statusCode,
        etag: response.headers['etag']?.replaceAll('"', ''),
      );
    });
  }

  Future<Result<T>> _safeCall<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return success<T>(data);
    } on ApiException catch (e) {
      _debugUploadLog(
        'ApiException: status=${e.statusCode}, message=${e.message}, '
        'errorCode=${e.errorCode}, responseBody=${e.responseBody}',
      );
      return fail<T>(ErrorMapper.mapApiException(e));
    } catch (e) {
      _debugUploadLog('Exception: type=${e.runtimeType}, message=$e');
      return fail<T>(ErrorMapper.mapException(e));
    }
  }

  void _debugUploadLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[FilesRepository][Upload] $message');
  }

  String _preview(String value, {int max = 240}) {
    final singleLine = value.replaceAll('\n', ' ').trim();
    if (singleLine.length <= max) return singleLine;
    return '${singleLine.substring(0, max)}...';
  }

  String _checksumPrefix(String checksum) {
    if (checksum.isEmpty) return 'empty';
    return checksum.length <= 12 ? checksum : checksum.substring(0, 12);
  }

  String _pathTail(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    final segments = trimmed
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return '/';
    if (segments.length == 1) return '/${segments.first}';
    return '/${segments[segments.length - 2]}/${segments.last}';
  }
}
