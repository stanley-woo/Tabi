import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FileService {
  static const _base = 'http://localhost:8000';

  /// Upload a single image file and returns the public URL.
  static Future<String> uploadImage(File file) async {
    final uri = Uri.parse('$_base/upload-image');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Image upload failed (${streamed.statusCode})');
    }
    final body = await streamed.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final urlPath = data['url'] as String;
    return urlPath.startsWith('http') 
        ? urlPath 
        : '$_base$urlPath';
  }
}