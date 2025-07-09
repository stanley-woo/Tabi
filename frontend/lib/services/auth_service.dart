typedef AuthToken = String;

class AuthService {
  /// Mock Login: accepts only demo@tabi.app / password
  static Future<bool> login(String email, String pass) async {
    await Future.delayed(const Duration(seconds: 1));
    return email == 'demo@tabi.app' && pass == 'password';
  }

  /// Mock token retrieval: returns a placeholder token or null
  static Future<AuthToken> getToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'stub-token';
  }

  static Future<void> logout() async {
    
  }
}