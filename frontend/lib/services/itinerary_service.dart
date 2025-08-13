import 'dart:convert';
import 'package:frontend/services/api.dart';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';
import 'profile_service.dart';

class ItineraryService {
  static String get _base => baseUrl;

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
  static Future<int> createItinerary({required String title, required String description, required bool isPublic, required List<String> tags, required int creatorId}) async {
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
  static Future<void> createBlock({required int itineraryId, required int dayGroupId, required int order,
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

  /// Fetch itineraries CREATED by a given username (typed List<Itinerary>).
  /// Uses /users/{username}/itineraries.
  static Future<List<Itinerary>> fetchCreatedByUsername(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/itineraries'));
    if(r.statusCode != 200) {
      throw Exception('Failed to load created trips for $username (${r.statusCode})');
    }

    final List<dynamic> body = jsonDecode(r.body);
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Fetch itineraries SAVED by a given username (typed List<Itinerary>).
  /// Uses /users/{username}/saved.
  static Future<List<Itinerary>> fetchSavedByUsername(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/saved'));
    if(r.statusCode != 200) {
      throw Exception('Failed to load saved trips for $username (${r.statusCode})');
    }

    final List<dynamic> body = jsonDecode(r.body);
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Convenience: create an itinerary "as" a username.
  /// Resolves username -> userId via ProfileService, then calls your existing createItinerary().
  static Future<int> createForUsername({required String username, required String title, String description = '', bool isPublic = true, List<String> tags = const []}) async {
    final userId = await ProfileService.getUserIdByUsername(username);
    if(userId == null) {
      throw Exception('No such user: $username');
    }

    return createItinerary(title: title, description: description, isPublic: isPublic, tags: tags, creatorId: userId);
  }

  /// Resolves username -> userId, then calls your existing forkItinerary().
  static Future<Itinerary> forkForUsername({
    required int originalItineraryId,
    required String newCreatorUsername,
  }) async {
    final userId = await ProfileService.getUserIdByUsername(newCreatorUsername);
    if (userId == null) {
      throw Exception('No such user: $newCreatorUsername');
    }
    return forkItinerary(
      originalItineraryId: originalItineraryId,
      newCreatorId: userId,
    );
  }
}