import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

String get baseUrl {
  if(kIsWeb) return 'http://localhost:8000';
  if(defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

dynamic jsonOrThrow(http.Response r) {
  if(r.statusCode < 200 || r.statusCode >= 300) {
    throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }

  return r.body.isNotEmpty ? json.decode(r.body) : null;
}