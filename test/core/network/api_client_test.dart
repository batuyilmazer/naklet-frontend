import 'dart:convert';

import 'package:flutter_frontend_boilerplate/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient({this.statusCode = 200, this.responseBody = '{}'});

  final int statusCode;
  final String responseBody;

  Uri? lastUrl;
  String? lastMethod;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    lastMethod = request.method;
    lastHeaders = Map<String, String>.from(request.headers);

    if (request is http.Request) {
      lastBody = request.body;
    }

    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(responseBody)),
      statusCode,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('ApiClient URL normalization', () {
    test(
      'builds URL without double slash when base has trailing slash and path has leading slash',
      () async {
        final httpClient = RecordingHttpClient();
        final apiClient = ApiClient(
          httpClient: httpClient,
          baseUrl: 'https://naklet-api.ituacm.com/',
        );

        await apiClient.getJson('/search/nearby');

        expect(
          httpClient.lastUrl.toString(),
          'https://naklet-api.ituacm.com/search/nearby',
        );
      },
    );

    test(
      'builds URL correctly when path does not include leading slash',
      () async {
        final httpClient = RecordingHttpClient();
        final apiClient = ApiClient(
          httpClient: httpClient,
          baseUrl: 'https://naklet-api.ituacm.com',
        );

        await apiClient.getJson('drivers/me');

        expect(
          httpClient.lastUrl.toString(),
          'https://naklet-api.ituacm.com/drivers/me',
        );
      },
    );

    test(
      'attaches query parameters to normalized URL in GET requests',
      () async {
        final httpClient = RecordingHttpClient();
        final apiClient = ApiClient(
          httpClient: httpClient,
          baseUrl: 'https://naklet-api.ituacm.com/',
        );

        await apiClient.getJsonWithParams(
          '/search/nearby',
          queryParams: const {
            'lat': '41.0082',
            'lng': '28.9784',
            'radius': '15000',
          },
        );

        expect(httpClient.lastUrl?.path, '/search/nearby');
        expect(httpClient.lastUrl?.queryParameters['lat'], '41.0082');
        expect(httpClient.lastUrl?.queryParameters['lng'], '28.9784');
        expect(httpClient.lastUrl?.queryParameters['radius'], '15000');
      },
    );

    test(
      'attaches query parameters to normalized URL in POST requests',
      () async {
        final httpClient = RecordingHttpClient();
        final apiClient = ApiClient(
          httpClient: httpClient,
          baseUrl: 'https://naklet-api.ituacm.com/',
        );

        await apiClient.postJson(
          '/auth/verify-email',
          queryParams: const {'token': 'test-token'},
        );

        expect(httpClient.lastUrl?.path, '/auth/verify-email');
        expect(httpClient.lastUrl?.queryParameters['token'], 'test-token');
        expect(httpClient.lastMethod, 'POST');
      },
    );
  });
}
