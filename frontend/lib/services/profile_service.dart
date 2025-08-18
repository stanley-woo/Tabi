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

  /// List all users (backend: GET /users)
  static Future<List<Map<String, dynamic>>> listUsers() async {
    final r = await http.get(Uri.parse('$baseUrl/users'));
    final data = jsonOrThrow(r) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Convenience: client-side search by username or display_name
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    final all = await listUsers();
    if (q.isEmpty) return all;
    return all.where((u) {
      final uname = (u['username'] ?? '').toString().toLowerCase();
      final dname = (u['display_name'] ?? '').toString().toLowerCase();
      return uname.contains(q) || dname.contains(q);
    }).toList();
  }

  /// PUT /users/{username}/profile - send only the fields people want to change
  static Future<Map<String, dynamic>> updateProfile (String username, {String? displayName, String? bio, String? avatarName, String? headerUrl}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (bio != null) body['bio'] = bio;
    if (avatarName != null) body['avatar_name'] = avatarName;
    if (headerUrl != null) body['header_url'] = headerUrl;

    final r = await http.put(Uri.parse('$baseUrl/users/$username/profile'), headers: {'Content-type' : 'application/json'}, body: json.encode(body));
    return jsonOrThrow(r) as Map<String, dynamic>;
  }

  /// Quick check: is `username` already saving this itinerary?
  static Future<bool> isTripSaved(String username, int itineraryId) async {
    final saved = await fetchSaved(username);
    return saved.any((it) => (it as Map<String, dynamic>)['id'] == itineraryId);
  }
}