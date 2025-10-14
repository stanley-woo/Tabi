import 'api.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AuthToken = String;

class AuthService {
  static final _api = ApiClient.instance;
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }

    _api.setAccessToken(token);

    try {
      await me();
      return true;
    } catch (e) {
      await _clearStoredTokens();
      _api.setAccessToken(null);
      return false;
    }
  }

  static Future<void> _persistTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> _clearStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<void> register(String username, String email, String password) async {
    await _api.post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password
    });
  }

  static Future<void> login(String email, String password) async {
    final body = await _api.post('/auth/login', body: {'email': email, 'password': password}) as Map<String, dynamic>;

    final accessToken = body['access_token'] as String?;
    final refreshToken = body['refresh_token'] as String?;

    if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Login failed: token pair not received');
    }
    
    _api.setAccessToken(accessToken);
    await _persistTokens(accessToken, refreshToken);
  }

  static Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final oldRefreshToken = prefs.getString(_refreshTokenKey);
    if (oldRefreshToken == null) {
      throw Exception('No refresh token available');
    }

    final body = await _api.post('/auth/refresh', body: {'refresh_token': oldRefreshToken}) as Map<String, dynamic>;
    
    final newAccessToken = body['access_token'] as String?;
    final newRefreshToken = body['refresh_token'] as String?;

    if (newAccessToken == null || newRefreshToken == null) {
      throw Exception('Refresh failed: new token pair not received');
    }

    _api.setAccessToken(newAccessToken);
    await _persistTokens(newAccessToken, newRefreshToken);
  }

  static Future<Map<String, dynamic>> me() async {
    final body = await _api.get('/auth/me');
    return body as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken != null) {
      try {
        await _api.post('/auth/logout', body: {'refresh_token': refreshToken});
      } catch (e) {
        // Fail silently - user wants to log out anyway
        // Logout API call failed, but proceeding with local logout
      }
    }
    _api.setAccessToken(null);
    await _clearStoredTokens();
  }

  static Future<void> verifyEmail(String token) async {
    await _api.post('/auth/verify-email', body: {'token': token});
  }

  static Future<void> resendVerification(String email) async {
    await _api.post('/auth/resend-verification', body: {'email': email});
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/auth/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static String? get token => _api.accessToken;

  static Future<bool> validateStoredToken() async {
    return await init(); // init() now returns bool indicating validity
  }
}