// lib/services/profile_service.dart
import 'api.dart';

class ProfileService {
  static final _api = ApiClient.instance;

  static Future<Map<String, dynamic>> fetchProfile(String username) async {
    return await _api.get('/users/$username/profile') as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchCreated(String username) async {
    return await _api.get('/users/$username/itineraries') as List<dynamic>;
  }

  static Future<List<dynamic>> fetchSaved(String username) async {
    return await _api.get('/users/$username/saved') as List<dynamic>;
  }

  static Future<void> follow(String me, String targetUsername) async {
    await _api.post('/users/$me/follow', body: {'target_username': targetUsername});
  }

  static Future<void> unfollow(String me, String target) async {
    await _api.delete_('/users/$me/follow/$target');
  }

  static Future<void> saveTrip(String me, int itineraryId) async {
    await _api.post('/users/$me/bookmarks', body: {'itinerary_id': itineraryId});
  }

  static Future<void> unsaveTrip(String me, int itineraryId) async {
    await _api.delete_('/users/$me/bookmarks/$itineraryId');
  }

  static Future<List<Map<String, dynamic>>> fetchFollowers(String username) async {
    final list = await _api.get('/users/$username/followers') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchFollowing(String username) async {
    final list = await _api.get('/users/$username/following') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<bool> isFollowing(String me, String target) async {
    final list = await fetchFollowing(me);
    return list.any((p) => (p['username'] as String?) == target);
  }

  /// Resolve username → numeric id (for create)
  static Future<int?> getUserIdByUsername(String username) async {
    final list = await _api.get('/users') as List<dynamic>;
    final match = list
        .cast<Map<String, dynamic>>()
        .where((u) => u['username'] == username)
        .toList();
    return match.isNotEmpty ? (match.first['id'] as int) : null;
  }

  /// List all users (backend: GET /users)
  static Future<List<Map<String, dynamic>>> listUsers() async {
    final data = await _api.get('/users') as List<dynamic>;
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

    return await _api.put('/users/$username/profile', body: body) as Map<String, dynamic>;
  }

  /// Quick check: is `username` already saving this itinerary?
  static Future<bool> isTripSaved(String username, int itineraryId) async {
    final saved = await fetchSaved(username);
    return saved.any((it) => (it as Map<String, dynamic>)['id'] == itineraryId);
  }

  static Future<List<int>> fetchFollowingIds(String username) async {
    final data = await _api.get('/users/$username/following');
    if (data is! List) return const <int>[];   // extra guard

    final ids = data.map<int?>((raw) {
      if (raw is! Map) return null;
      final any = raw['id'] ?? raw['user_id'] ?? raw['following_id'];
      if (any is int) return any;
      if (any is num) return any.toInt();
      if (any is String) return int.tryParse(any);
      return null;
    }).whereType<int>().toList();

    // (optional) dedupe while preserving order
    final seen = <int>{};
    return ids.where((id) => seen.add(id)).toList();
  }


  static Future<void> deleteUser() async {
      final currentUser = await _api.get('/auth/me');
      final userId = currentUser['id'];
      await _api.delete_('/users/$userId');
  }
}