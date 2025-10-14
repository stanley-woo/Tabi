// lib/state/auth_store.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/api.dart';

class AuthStore extends ChangeNotifier {
  String? username;
  int? userId;
  bool loading = false;

  String get currentUsername => username ?? '';
  bool get isLoggedIn {
    final result = ApiClient.instance.accessToken != null;
    return result;
  }

  // ignore: prefer_final_fields
  Set<String> _followingUsernames = {};
  bool isFollowing(String username) => _followingUsernames.contains(username.toLowerCase());

  void _debugLog(String message) {
  }
  
  // Debug method to clear all stored data
  Future<void> clearAllData() async {
    await AuthService.logout();
    username = null;
    userId = null;
    _followingUsernames.clear();
    loading = false;
    notifyListeners();
  }
  
  // Test if the current token is valid by making a simple API call
  Future<void> testTokenValidity() async {
    try {
      await AuthService.me();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> boot() async {
    loading = true; 
    notifyListeners();

    try {
      // Initialize and validate stored token
      final hasValidToken = await AuthService.init();
      
      if (hasValidToken) {
        // Token is valid, fetch user info
        try {
          final me = await AuthService.me();
          username = me['username'] as String?;
          userId = (me['id'] as num?)?.toInt();
          _debugLog('User authenticated: $username (ID: $userId)');
        } catch (e) {
          _debugLog('Error fetching user info: $e');
          // Clear invalid session
          await AuthService.logout();
          username = null;
          userId = null;
        }
      } else {
        // No valid token, ensure clean state
        _debugLog('No valid token found');
        username = null;
        userId = null;
      }
    } catch (e) {
      _debugLog('Error during auth boot: $e');
      // Ensure clean state on any error
      await AuthService.logout();
      username = null;
      userId = null;
    }

    loading = false; 
    notifyListeners();
  }

  Future<void> registerAndLogin(String username, String email, String password) async {
    loading = true;
    notifyListeners();

    try {
      await AuthService.register(username, email, password);
      
      await loginWithCredentials(email, password);
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithCredentials(String email, String password) async {
    loading = true; 
    notifyListeners();
    
    try {
      // 1) Authenticate (now persists token automatically)
      await AuthService.login(email, password);

      // 2) Ask backend who we are (authoritative)
      final me = await AuthService.me();
      username = me['username'] as String?;
      userId = (me['id'] as num?)?.toInt();

      // User authentication completed
    } catch (err) {
      // Clear auth state on failure
      await AuthService.logout();
      username = null;
      userId = null;
      rethrow;
    } finally {
      loading = false; 
      notifyListeners();
    }

    await fetchFollowing();
  }

  Future<void> fetchFollowing() async {
    if (username == null) return;

    try {
      final followingList = await ProfileService.fetchFollowing(username!);
      _followingUsernames = followingList.map((user) => (user['username'] as String).toLowerCase()).toSet();
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }



  Future<void> follow(String targetUsername) async {
    if (username == null) return;
    await ProfileService.follow(username!, targetUsername);
    _followingUsernames.add(targetUsername.toLowerCase());
    notifyListeners();
  }

  Future<void> unfollow(String targetUsername) async {
    if (username == null) return;
    await ProfileService.unfollow(username!, targetUsername);
    _followingUsernames.remove(targetUsername.toLowerCase());
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();  // Now async to handle token cleanup
    username = null;
    userId = null;
    _followingUsernames.clear();
    loading = false;
    notifyListeners();
  }
}