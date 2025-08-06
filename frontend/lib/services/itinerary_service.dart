import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';

class ItineraryService {
  static const _base = 'http://localhost:8000';

  /// Fetch all root‐level itineraries.
  static Future<List<Itinerary>> fetchList() async {
    final resp = await http.get(Uri.parse('$_base/itineraries'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itineraries (${resp.statusCode})');
    }
    final List<dynamic> body = jsonDecode(resp.body);
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Fetch a single itinerary, _including_ its days & blocks.
  static Future<Itinerary> fetchDetail(int id) async {
    final resp = await http.get(Uri.parse('$_base/itineraries/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itinerary ($id): ${resp.statusCode}');
    }
    return Itinerary.fromJson(jsonDecode(resp.body));
  }

  /// Create a new itinerary. Returns the created ID.
  static Future<int> createItinerary({
    required String title,
    required String description,
    required bool isPublic,
    required List<String> tags,
    required int creatorId,
  }) async {
    final uri = Uri.parse('$_base/itineraries');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'visibility': isPublic ? 'public' : 'private',
        'tags': tags,
        'creator_id': creatorId,
      }),
    );
    if (resp.statusCode != 201) {
      throw Exception(
          'Failed to create itinerary (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  /// Fork an existing itinerary under a new creator.
  /// Returns the new itinerary.
  static Future<Itinerary> forkItinerary({
    required int originalItineraryId,
    required int newCreatorId,
  }) async {
    final uri =
        Uri.parse('$_base/itineraries/$originalItineraryId/fork');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'creator_id': newCreatorId}),
    );
    if (resp.statusCode != 201) {
      throw Exception(
          'Failed to fork itinerary ($originalItineraryId): ${resp.body}');
    }
    return Itinerary.fromJson(jsonDecode(resp.body));
  }

  /// Create a new block _within_ a specific day‐group.
  static Future<void> createBlock({
    required int itineraryId,
    required int dayGroupId,
    required int order,
    required String type,    // 'text' | 'image' | 'map'
    required String content, // text, URL, or "lat,lng"
  }) async {
    final uri = Uri.parse(
      '$_base/itineraries/$itineraryId/days/$dayGroupId/blocks',
    );
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
          'Failed to create block (day $dayGroupId, ord $order): ${resp.body}');
    }
  }
}