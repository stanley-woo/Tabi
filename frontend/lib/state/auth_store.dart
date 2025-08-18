// lib/state/auth_store.dart
import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class AuthStore extends ChangeNotifier {
  String? username;
  int? userId;
  bool loading = false;

  String get currentUsername => username ?? 'julieee_mun'; // safe fallback
  bool get isLoggedIn => username != null && userId != null;

  Future<void> loginWithDemoEmail(String email) async {
    loading = true; notifyListeners();
    final e = email.toLowerCase();

    // Map demo emails -> usernames
    if (e == 'demo@tabi.app' || e == 'julie@tabi.app') {
      username = 'julieee_mun';
    } else if (e == 'sarah@tabi.app') {
      username = 'sarah_kuo';
    } else {
      username = email.split('@').first;
    }

    await _resolveUserId();
    loading = false; notifyListeners();
  }

  // Handy direct switch (no email needed)
  Future<void> loginAs(String uname) async {
    loading = true; notifyListeners();
    username = uname;
    await _resolveUserId();
    loading = false; notifyListeners();
  }

  Future<void> _resolveUserId() async {
    userId = await ProfileService.getUserIdByUsername(username!);
    if (userId == null) {
      // (Optional) create the user here or throw
      debugPrint('AuthStore: username "$username" not found on server.');
    }
  }

  void logout() {
    username = null; userId = null;
    notifyListeners();
  }
}