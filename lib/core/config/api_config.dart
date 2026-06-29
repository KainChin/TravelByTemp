import 'package:flutter/foundation.dart';

/// Base URL for VietAI backend.
///
/// Physical Android phone: use the computer LAN IP.
/// Android emulator: run with API_BASE_URL=http://10.0.2.2:5000.
/// iOS simulator / desktop / web: localhost.
abstract final class ApiConfig {
  static const int port = 5000;
  static const requestTimeout = Duration(seconds: 12);
  static const _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:$port';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.26:$port';
    }
    return 'http://localhost:$port';
  }
}
