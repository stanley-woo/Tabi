import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';

class ItineraryService {
  static const _base = 'http://localhost:8000';

  static Future<int> createItinerary({
    required String title,
    required String description,
    required bool isPublic,
    required List<String> tags,
    required int creatorId
  }) async {
    final uri = Uri.parse('$_base/itineraries');
    final resp = await http.post(
      uri, 
      headers: {'Content-type' : 'application/json'}, 
      body: jsonEncode({
        'title' : title,
        'description' : description,
        'visibility' : isPublic ? 'public' : 'private',
        'tags' : tags,
        'creator_id' : creatorId
      }),
    );

    if (resp.statusCode != 201) {
      throw Exception(
          'Failed to create itinerary (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  /// Creates a single block for the given itinerary.
  static Future<void> createBlock({
    required int itineraryId,
    required int order,
    required String type, // 'text' or 'image'
    required String content,
  }) async {
    final uri = Uri.parse('$_base/itineraries/$itineraryId/blocks');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'order': order,
        'type': type,
        'content': content,
      }),
    );
    if (resp.statusCode != 201) {
      throw Exception(
          'Failed to create block #$order (${resp.statusCode}): ${resp.body}');
    }
  }

  static Future<Itinerary> fetchDetail(int id) async {
    final resp = await http.get(Uri.parse('$_base/itineraries/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itinerary.');
    }
    return Itinerary.fromJson(jsonDecode(resp.body));
  }

  static Future<List<Itinerary>> fetchList() async {
    final resp = await http.get(Uri.parse('$_base/itineraries/'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itineraries');
    }
    final List<dynamic> body = jsonDecode(resp.body);
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }
}