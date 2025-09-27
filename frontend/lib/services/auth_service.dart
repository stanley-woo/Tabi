import 'api.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AuthToken = String;

class AuthService {
  static final _api = ApiClient.instance;
  static const _tokenKey = 'accessToken';

  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }

    _api.setAccessToken(token);

    try {
      await me();
      return true;
    } catch (e) {
      await _clearStoredToken();
      _api.setAccessToken(null);
      return false;
    }
  }

  static Future<void> _persistenToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<AuthToken> login(String email, String password) async {
    final body = await _api.post('/auth/login', body: {'email': email, 'password': password}) as Map<String, dynamic>;

    final token = body['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login failed: no access_token in response');
    }
    // persist into ApiClient so other calls get the header
    _api.setAccessToken(token);
    await _persistenToken(token);
    return token;
  }

  static Future<Map<String, dynamic>> me() async {
    final body = await _api.get('/auth/me');
    return body as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    _api.setAccessToken(null);
    await _clearStoredToken();
  }

  static String? get token => _api.accessToken;

  static Future<bool> validateStoredToken() async {
    return await init(); // init() now returns bool indicating validity
  }
}