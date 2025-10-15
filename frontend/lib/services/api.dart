// lib/services/api.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb, VoidCallback;
import 'package:http/http.dart' as http;

// Import AuthService to access the refreshToken method
import 'auth_service.dart';
import '../config/app_config.dart';

/// API client with automatic token refresh interception.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _accessToken;
  VoidCallback? onAuthenticationFailed;

  // --- NEW: Refresh logic state ---
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  // ---- Base URL resolution ----
  String get baseUrl {
    // Use production URL if configured
    if (AppConfig.isProduction) {
      return AppConfig.backendUrl;
    }
    
    // Development URLs
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // ---- Token management ----
  void setAccessToken(String? token) => _accessToken = token;
  String? get accessToken => _accessToken;

  // ---- Centralized Request Handler with Interception ---
  Future<http.Response> _makeRequest(Future<http.Response> Function() requestFunction) async {
    // If a refresh is already in progress, wait for it to complete
    if (_isRefreshing) {
      await _refreshCompleter?.future;
    }
    
    var response = await requestFunction();

    if (response.statusCode == 401) {
      if (_isRefreshing) {
        // Another request triggered a refresh, wait for it and retry
        await _refreshCompleter?.future;
        response = await requestFunction();
      } else {
        // This is the first request to fail, start the refresh process
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();

        try {
          await AuthService.refreshToken();
          _refreshCompleter!.complete(); // Signal that refresh is done
          // Retry the original request with the new token
          response = await requestFunction();
        } catch (e) {
          // Token refresh failed
          _refreshCompleter!.completeError(e); // Signal that refresh failed
          onAuthenticationFailed?.call(); // Trigger global logout
          throw AuthException('Your session has expired. Please log in again.');
        } finally {
          _isRefreshing = false;
        }
      }
    }
    
    return response;
  }

  // ---- Headers helper ----
  Map<String, String> _headers([Map<String, String>? extra]) => {
        'content-type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        ...?extra,
      };

  // ---- Response Handler ----
  dynamic _jsonOrThrow(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      // Try to parse error message from response
      String errorMessage;
      try {
        final body = json.decode(r.body);
        errorMessage = body['detail'] ?? 'An error occurred';
      } catch (_) {
        errorMessage = 'HTTP ${r.statusCode}: ${r.body}';
      }
      // Use the specific AuthException for 401, as other parts of the app may rely on it
      if (r.statusCode == 401) throw AuthException(errorMessage);
      throw ApiException(errorMessage);
    }
    return r.body.isNotEmpty ? json.decode(r.body) : null;
  }

  // ---- Basic verbs now use the interceptor ----
  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _makeRequest(() => http.get(uri, headers: _headers(headers)));
    return _jsonOrThrow(response);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _makeRequest(() => http.post(uri, headers: _headers(headers), body: json.encode(body)));
    return _jsonOrThrow(response);
  }

  Future<dynamic> patch(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _makeRequest(() => http.patch(uri, headers: _headers(headers), body: json.encode(body)));
    return _jsonOrThrow(response);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _makeRequest(() => http.put(uri, headers: _headers(headers), body: json.encode(body)));
    return _jsonOrThrow(response);
  }

  Future<void> delete_(String path, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _makeRequest(() => http.delete(uri, headers: _headers(headers)));
    _jsonOrThrow(response);
  }
  
  // (Your multipart helper can also be wrapped if needed, though less common for auth-heavy requests)
  Future<dynamic> multipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    // This is a simplified version. A full implementation would need to rebuild the request.
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers({'content-type': 'multipart/form-data'}))
        ..fields.addAll(fields ?? {})
        ..files.addAll(files ?? []);
        
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      // For simplicity, we'll just throw here. A full implementation
      // would require re-caching the files/fields to retry the request.
      onAuthenticationFailed?.call();
      throw AuthException('Session expired during upload. Please log in again.');
    }

    return _jsonOrThrow(response);
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