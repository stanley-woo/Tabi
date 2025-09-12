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
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      final withSlash = p.startsWith('/') ? p : '/$p';
      return '$baseUrl$withSlash';
    }
}