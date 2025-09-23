import 'api.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AuthToken = String;

class AuthService {
  static final _api = ApiClient.instance;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token != null) {
      ApiClient.instance.setAccessToken(token);
    }
  }

  static Future<AuthToken> login(String email, String password) async {
    final body = await _api.post('/auth/login', body: {'email': email, 'password': password}) as Map<String, dynamic>;

    final token = body['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login failed: no access_token in response');
    }
    // persist into ApiClient so other calls get the header
    _api.setAccessToken(token);
    return token;
  }

  static Future<Map<String, dynamic>> me() async {
    final body = await _api.get('/auth/me');
    return body as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    _api.setAccessToken(null);
  }

  static String? get token => _api.accessToken;
}