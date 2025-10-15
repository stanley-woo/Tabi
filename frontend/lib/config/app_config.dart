// lib/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _devBackendUrl = 'http://localhost:8000';
  static const String _prodBackendUrl = 'https://your-production-url.run.app'; // Update this with your actual GCP Cloud Run URL
  
  static String get backendUrl {
    if (kDebugMode) {
      return _devBackendUrl;
    }
    return _prodBackendUrl;
  }
  
  static bool get isProduction => !kDebugMode;
  static bool get isDevelopment => kDebugMode;
}
