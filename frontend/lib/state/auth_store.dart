// lib/state/auth_store.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/api.dart';

class AuthStore extends ChangeNotifier {
  String? username;
  int? userId;
  bool loading = false;

  String get currentUsername => username ?? 'julieee_mun';
  bool get isLoggedIn => ApiClient.instance.accessToken != null;

  Future<void> boot() async {
    loading = true; notifyListeners();

    // If ApiClient persisted a token in boot(), try to fetch /auth/me here.
    final token = ApiClient.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        final me = await AuthService.me();
        username  = me['username'] as String?;
        userId    = (me['id'] as num?)?.toInt();
      } catch (_) {
        // token invalid → clear
        await AuthService.logout();
        username = null; userId = null;
      }
    }

    loading = false; notifyListeners();
  }

  Future<void> loginWithCredentials(String email, String password) async {
    loading = true; notifyListeners();
    try {
      // 1) Authenticate (this also sets ApiClient.instance.accessToken)
      await AuthService.login(email, password);

      // 2) Ask backend who we are (authoritative)
      final me = await AuthService.me();
      username = me['username'] as String?;
      userId   = (me['id'] as num?)?.toInt();

      // 3) DEV ONLY: if you want demo email to *view as* a different profile
      // while still keeping the admin token, remap here.
      // (Comment this out in production.)
      final e = email.toLowerCase();
      if (e == 'demo@tabi.app') {
        // Keep the admin token, but switch which profile the UI shows
        // (Use any username you want to preview)
        await devQuickSwitchProfile('pikachu');
      }
    } catch (err) {
      // clear auth state on failure
      await AuthService.logout();
      username = null;
      userId = null;
      rethrow;
    } finally {
      loading = false; 
      notifyListeners();
    }
  }

  // Dev-only: keep admin token but jump to another profile view
  Future<void> devQuickSwitchProfile(String uname) async {
    username = uname;
    await _resolveUserId();
    notifyListeners();
  }

  Future<void> _resolveUserId() async {
    if (username == null) return;
    userId = await ProfileService.getUserIdByUsername(username!);
  }

  void logout() {
    AuthService.logout();
    username = null;
    userId = null;
    notifyListeners();
  }
}