import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';

class ImageUploadService {
  static final _api = ApiClient.instance;
  static final _picker = ImagePicker();

  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image file to backend
  static Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${_api.baseUrl}/files/upload-image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header if available
      final token = _api.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final url = data['url'] as String;
        // Extract just the filename from the URL (remove /static/ prefix)
        if (url.startsWith('/static/')) {
          return url.substring(8); // Remove '/static/' prefix
        }
        return url;
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Pick and upload image in one step
  static Future<String?> pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final imageFile = await pickImage(source: source);
      if (imageFile == null) return null;
      
      final file = File(imageFile.path);
      return await uploadImage(file);
    } catch (e) {
      throw Exception('Failed to pick and upload image: $e');
    }
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
