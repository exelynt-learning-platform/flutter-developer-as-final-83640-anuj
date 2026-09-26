import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String baseUrl = _defaultBaseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://669b3f09276e45187d34eb4e.mockapi.io/api/v1';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<dynamic> get(String path) => _send(() => _client.get(_uri(path)));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send(() => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => _client.delete(_uri(path)));

  Map<String, String> get _headers => const {'Content-Type': 'application/json'};

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      if (response.statusCode == 404) {
        throw ApiException('Not found', statusCode: 404);
      }
      throw ApiException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw ApiException('No internet connection');
    } on HttpException {
      throw ApiException('Could not reach the server');
    } on FormatException {
      throw ApiException('Received an invalid response from the server');
    }
  }
}
