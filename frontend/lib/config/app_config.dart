// lib/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  // static const String _devBackendUrl = 'http://localhost:8000';
  static const String _devBackendUrl = 'http://192.168.68.67:8000';
  static const String _prodBackendUrl = 'https://tabi-backend-mmpsmclhjq-uw.a.run.app';
  
  static String get backendUrl {
    return _prodBackendUrl;
  }
  
  static bool get isProduction => !kDebugMode;
  static bool get isDevelopment => kDebugMode;
}
