import 'dart:convert';
import 'dart:io';

import 'package:exelynt_learning/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    apiClient = ApiClient(client: mockClient, baseUrl: 'https://api.test/v1');
  });

  group('get', () {
    test('returns decoded JSON on 200', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode([
          {'id': '1'},
        ]), 200),
      );

      final result = await apiClient.get('/employee');

      expect(result, [
        {'id': '1'},
      ]);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response('', 404));

      expect(
        () => apiClient.get('/employee/999'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('throws ApiException on server error', () async {
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response('', 500));

      expect(() => apiClient.get('/employee'), throwsA(isA<ApiException>()));
    });

    test('wraps SocketException as ApiException', () async {
      when(() => mockClient.get(any())).thenThrow(const SocketException('no network'));

      expect(
        () => apiClient.get('/employee'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'No internet connection')),
      );
    });
  });

  group('post', () {
    test('sends JSON body and returns decoded response', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'id': '1', 'name': 'A'}), 201));

      final result = await apiClient.post('/employee', {'name': 'A'});

      expect(result, {'id': '1', 'name': 'A'});
      final captured = verify(
        () => mockClient.post(any(), headers: any(named: 'headers'), body: captureAny(named: 'body')),
      ).captured.single as String;
      expect(jsonDecode(captured), {'name': 'A'});
    });
  });

  group('delete', () {
    test('returns null for an empty successful response body', () async {
      when(() => mockClient.delete(any())).thenAnswer((_) async => http.Response('', 200));

      final result = await apiClient.delete('/employee/1');

      expect(result, isNull);
    });
  });
}
