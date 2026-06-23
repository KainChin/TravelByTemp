import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Base URL VietAI backend.
/// - Android emulator: 10.0.2.2 → host localhost
/// - iOS simulator / desktop: localhost
abstract final class ApiConfig {
  static const int port = 5000;
  static const _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:$port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port';
    return 'http://localhost:$port';
  }
}
