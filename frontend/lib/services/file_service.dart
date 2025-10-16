import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api.dart' show baseUrl, ApiClient;

class FileService {
  /// Upload a single image file and return its public URL.
  static Future<String> uploadImage(File file) async {
    final uri = Uri.parse('$baseUrl/files/upload-image');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final token = ApiClient.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Image upload failed (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final urlPath = (data['url'] ?? data['path'] ?? data['location']) as String;
    return absoluteUrl(urlPath);
  }

  static String absoluteUrl(String path) {
    final p = path.trim();
    if (p.startsWith('assets/')) return p;
    if (p.startsWith('http://') || p.startsWith('https://')) {
      // If it's already a full URL, check if it's localhost and replace it
      if (p.contains('localhost:8000')) {
        final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
        final cleanPath = p.substring(p.indexOf('/static/'));
        final fullUrl = '$cleanBaseUrl$cleanPath';
        print('DEBUG: Rewritten localhost URL: $fullUrl');
        return fullUrl;
      }
      return p;
    }
    
    // Ensure baseUrl doesn't end with slash and path starts with slash
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = p.startsWith('/') ? p : '/$p';
    final fullUrl = '$cleanBaseUrl$cleanPath';
    print('DEBUG: Generated image URL: $fullUrl');
    return fullUrl;
  }
}