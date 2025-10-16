import 'package:frontend/services/api.dart';
import '../models/itinerary.dart';
import 'profile_service.dart';

class ItineraryService {
  static final _api = ApiClient.instance;

  /// Fetch all root‐level itineraries.
  static Future<List<Itinerary>> fetchList() async {
    final body = await _api.get('/itineraries') as List<dynamic>;
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Fetch a single itinerary, _including_ its days & blocks.
  static Future<Itinerary> fetchDetail(int id) async {
    final body = await _api.get('/itineraries/$id') as Map<String, dynamic>;
    return Itinerary.fromJson(body);
  }

  /// Create a new itinerary. Returns the created ID.
  static Future<int> createItinerary({required String title, required String description, required bool isPublic, required List<String> tags, required DateTime start_date}) async {
    final payload = {
      'title': title,
      'description': description,
      'visibility': isPublic ? 'public' : 'private',
      'tags': tags,
      'start_date': start_date.toIso8601String().split('T')[0],
    };
    final body = await _api.post('/itineraries', body: payload)
        as Map<String, dynamic>;
    return body['id'] as int;
  }

  /// Fork an existing itinerary under a new creator.
  /// Returns the new itinerary.
  static Future<Itinerary> forkItinerary({required int originalItineraryId}) async {
    final body = await _api.post('/itineraries/$originalItineraryId/fork') as Map<String, dynamic>;
    return Itinerary.fromJson(body);
  }

  /// Create a new block _within_ a specific day‐group.
  static Future<void> createBlock({required int itineraryId, required int dayGroupId, required int order,
    required String type,    // 'text' | 'image' | 'map'
    required String content, // text, URL, or "lat,lng"
  }) async {
    await _api.post(
      '/itineraries/$itineraryId/days/$dayGroupId/blocks',
      body: {
        'order': order,
        'type': type,
        'content': content,
      },
    );
  }

  /// Fetch itineraries CREATED by a given username.
  /// Uses /users/{username}/itineraries.
  static Future<List<Itinerary>> fetchCreatedByUsername(String username) async {
    final body = await _api.get('/users/$username/itineraries')
        as List<dynamic>;
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Fetch itineraries SAVED by a given username.
  /// Uses /users/{username}/saved.
  static Future<List<Itinerary>> fetchSavedByUsername(String username) async {
    final body = await _api.get('/users/$username/saved')
        as List<dynamic>;
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }

  /// Convenience: create an itinerary "as" a username.
  /// Resolves username -> userId via ProfileService, then calls your existing createItinerary().
  static Future<int> createForUsername({required String username, required String title, String description = '', bool isPublic = true, List<String> tags = const [], required DateTime start_date}) async {
    final userId = await ProfileService.getUserIdByUsername(username);
    if(userId == null) {
      throw Exception('No such user: $username');
    }

    return createItinerary(title: title, description: description, isPublic: isPublic, tags: tags, start_date: start_date);
  }

  /// Resolves username -> userId, then calls your existing forkItinerary().
  static Future<Itinerary> forkForUsername({
    required int originalItineraryId,
    required String newCreatorUsername,
  }) async {
    return forkItinerary(originalItineraryId: originalItineraryId);
  }

  static Future<void> deleteItinerary(int itineraryId) async {
    await _api.delete_('/itineraries/$itineraryId');
  }
}