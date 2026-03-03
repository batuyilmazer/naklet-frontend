import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'auth_interceptor.dart';

/// Very small HTTP client wrapper around `package:http`.
///
/// This is intentionally minimal; you can replace it with Dio or another
/// client later without touching feature modules.
///
/// Supports optional [AuthInterceptor] for automatic token injection and refresh.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    AuthInterceptor? authInterceptor,
    String? baseUrl,
  }) : _client = httpClient ?? http.Client(),
       _authInterceptor = authInterceptor,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final AuthInterceptor? _authInterceptor;
  final String _baseUrl;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    return await _executeRequest(() async {
      final modifiedHeaders = _authInterceptor != null
          ? await _authInterceptor.interceptRequest(headers)
          : headers;
      final uri = _buildUri(path);
      final response = await _client.get(uri, headers: modifiedHeaders);
      return response;
    });
  }

  Future<Map<String, dynamic>> getJsonWithParams(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    return await _executeRequest(() async {
      final modifiedHeaders = _authInterceptor != null
          ? await _authInterceptor.interceptRequest(headers)
          : headers;
      final uri = _buildUri(path, queryParams: queryParams);
      final response = await _client.get(uri, headers: modifiedHeaders);
      return response;
    });
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Object? body,
  }) async {
    return await _executeRequest(() async {
      final baseHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };
      final modifiedHeaders = _authInterceptor != null
          ? await _authInterceptor.interceptRequest(baseHeaders)
          : baseHeaders;
      final uri = _buildUri(path, queryParams: queryParams);
      final response = await _client.post(
        uri,
        headers: modifiedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    return await _executeRequest(() async {
      final modifiedHeaders = _authInterceptor != null
          ? await _authInterceptor.interceptRequest(headers)
          : headers;
      final uri = _buildUri(path);
      final response = await _client.delete(uri, headers: modifiedHeaders);
      return response;
    });
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await _executeRequest(() async {
      final baseHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };
      final modifiedHeaders = _authInterceptor != null
          ? await _authInterceptor.interceptRequest(baseHeaders)
          : baseHeaders;
      final uri = _buildUri(path);
      final response = await _client.patch(
        uri,
        headers: modifiedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
      return response;
    });
  }

  /// Execute HTTP request with interceptor support.
  ///
  /// Handles automatic token injection and 401 refresh retry logic.
  Future<Map<String, dynamic>> _executeRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    http.Response response;
    try {
      response = await requestFn();
    } catch (e) {
      rethrow;
    }

    // Handle 401 with refresh retry if interceptor is available
    if (response.statusCode == 401 && _authInterceptor != null) {
      try {
        // Interceptor will attempt refresh and retry
        return await _authInterceptor.interceptResponse(() async {
          // Retry original request with new token
          final retryResponse = await requestFn();
          return _handleJsonResponse(retryResponse);
        });
      } catch (e) {
        // Refresh failed, throw original 401 response
        return _handleJsonResponse(response);
      }
    }

    return _handleJsonResponse(response);
  }

  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    final base = _baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final cleanPath = path.replaceFirst(RegExp(r'^/+'), '');
    final normalizedPath = cleanPath.isEmpty ? '' : '/$cleanPath';

    return Uri.parse(
      '$base$normalizedPath',
    ).replace(queryParameters: queryParams);
  }

  Map<String, dynamic> _handleJsonResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint(
        'HTTP ${response.request?.method} '
        '${response.request?.url} -> ${response.statusCode}',
      );
    }

    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    if (kDebugMode && decoded is Map<String, dynamic>) {
      debugPrint('HTTP error body: $decoded');
    }

    throw ApiException(
      decoded is Map<String, dynamic>
          ? (decoded['message']?.toString() ??
                decoded['Error']?.toString() ??
                decoded['error']?.toString() ??
                'Request failed')
          : 'Request failed',
      statusCode: response.statusCode,
      errorCode: decoded is Map<String, dynamic>
          ? (decoded['Error']?.toString() ?? decoded['error']?.toString())
          : null,
      responseBody: decoded is Map<String, dynamic> ? decoded : null,
    );
  }
}
