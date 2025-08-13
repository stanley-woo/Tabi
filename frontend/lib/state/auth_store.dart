// Purpose: when user "logs in" (demo@tabi.app), we map to Julie's username,
// resolve her numeric id (for create), and keep both in memory.

import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class AuthStore  extends ChangeNotifier {
  String? username;
  int? userId;
  bool loading = false;

  /// For demo: map email → username; then fetch userId from /users.
  Future<void> loginWithDemoEmail(String email) async {
    loading = true;
    notifyListeners();

    // 1) map demo email → username
    if (email.toLowerCase() == 'demo@tabi.app') {
      username = 'julieee_mun';
    } else {
      // fallback: treat local-part as username (or handle your own logic)
      username = email.split('@').first;
    }

    // 2) resolve numeric id so we can create itineraries
    userId = await ProfileService.getUserIdByUsername(username!);

    loading = false;
    notifyListeners();
  }

  bool get isLoggedIn => username != null && userId != null;
}