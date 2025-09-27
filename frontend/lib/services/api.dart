// lib/services/api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

/// Lightweight API client with bearer auth and JSON helpers.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _accessToken;

  // ---- Base URL resolution (same logic you had) ----
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // ---- Token management ----
  void setAccessToken(String? token) => _accessToken = token;
  String? get accessToken => _accessToken;

  // ---- Headers / JSON helpers ----
  Map<String, String> _headers([Map<String, String>? extra]) => {
        'content-type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        ...?extra,
      };

  void Function()? onAuthenticationFailed;
  dynamic _jsonOrThrow(http.Response r) {
    if (r.statusCode == 401) {
      _accessToken = null;
      
      // Notify any listeners about auth failure
      onAuthenticationFailed?.call();
      
      // Parse error detail if available
      String errorMessage = 'Authentication failed - please log in again';
      try {
        final body = json.decode(r.body);
        if (body is Map && body.containsKey('detail')) {
          errorMessage = body['detail'].toString();
        }
      } catch (_) {}
      
      throw AuthException(errorMessage);
    }
    
    if (r.statusCode < 200 || r.statusCode >= 300) {
      // Try to parse error message from response
      String errorMessage = 'HTTP ${r.statusCode}';
      try {
        final body = json.decode(r.body);
        if (body is Map && body.containsKey('detail')) {
          errorMessage = body['detail'].toString();
        } else {
          errorMessage = 'HTTP ${r.statusCode}: ${r.body}';
        }
      } catch (_) {
        errorMessage = 'HTTP ${r.statusCode}: ${r.body}';
      }
      throw ApiException(errorMessage);
    }
    
    return r.body.isNotEmpty ? json.decode(r.body) : null;
  }

  

  // ---- Basic verbs ----
  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await http.get(uri, headers: _headers(headers));
    return _jsonOrThrow(r);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final r =
        await http.post(uri, headers: _headers(headers), body: json.encode(body));
    return _jsonOrThrow(r);
  }

  Future<dynamic> patch(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await http.patch(uri,
        headers: _headers(headers), body: json.encode(body));
    return _jsonOrThrow(r);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await http.put(uri, headers: _headers(headers), body: json.encode(body));
    return _jsonOrThrow(r);
  }

  Future<void> delete_(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await http.delete(uri, headers: _headers(headers));
    _jsonOrThrow(r);
  }

  // ---- (Optional) Multipart helper for uploads ----
  Future<dynamic> multipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers({'content-type': 'multipart/form-data'}));
    if (fields != null) req.fields.addAll(fields);
    if (files != null) req.files.addAll(files);
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return _jsonOrThrow(r);
  }
  
}

String get baseUrl => ApiClient.instance.baseUrl;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}