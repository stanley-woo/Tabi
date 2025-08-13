// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class ProfileService {
  static Future<Map<String, dynamic>> fetchProfile(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/profile'));
    return jsonOrThrow(r) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchCreated(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/itineraries'));
    return jsonOrThrow(r) as List<dynamic>;
  }

  static Future<List<dynamic>> fetchSaved(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/saved'));
    return jsonOrThrow(r) as List<dynamic>;
  }

  static Future<void> follow(String me, String targetUsername) async {
    final r = await http.post(
      Uri.parse('$baseUrl/users/$me/follow'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'target_username': targetUsername}),
    );
    jsonOrThrow(r);
  }

  static Future<void> unfollow(String me, String target) async {
    final r = await http.delete(Uri.parse('$baseUrl/users/$me/follow/$target'));
    jsonOrThrow(r);
  }

  static Future<void> saveTrip(String me, int itineraryId) async {
    final r = await http.post(
      Uri.parse('$baseUrl/users/$me/bookmarks'),
      headers: {'Content-Type' : 'application/json'},
      body: json.encode({'itinerary_id': itineraryId}),
    );
    jsonOrThrow(r);
  }

  static Future<void> unsaveTrip(String me, int itineraryId) async {
    final r = await http.delete(Uri.parse('$baseUrl/users/$me/bookmarks/$itineraryId'));
    jsonOrThrow(r);
  }

  static Future<List<Map<String, dynamic>>> fetchFollowers(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/followers'));
    final list = jsonOrThrow(r) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchFollowing(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$username/following'));
    final list = jsonOrThrow(r) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Convenience: is `me` following `target`? (client-side check)
  static Future<bool> isFollowing(String me, String target) async {
    final list = await fetchFollowing(me);
    return list.any((p) => (p['username'] as String?) == target);
  }

  /// Resolve username → numeric id (for create)
  static Future<int?> getUserIdByUsername(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/users'));
    final list = jsonOrThrow(r) as List<dynamic>;
    final match = list.cast<Map<String, dynamic>>().where((u) => u['username'] == username).toList();
    return match.isNotEmpty ? (match.first['id'] as int) : null;
  }
}