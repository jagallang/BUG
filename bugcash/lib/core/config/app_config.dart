import 'package:flutter/foundation.dart';

class AppConfig {
  // App Configuration Only - Firebase config is handled by firebase_options.dart
  static bool get isProduction => kReleaseMode;
  static bool get enableLogging => !isProduction && kDebugMode;

  // App-specific settings
  static const String appName = 'BugCash';
  static const String appVersion = '1.0.0';

  // Feature flags
  static bool get enableOfflineMode => true;
  static bool get enablePushNotifications => true;
  static bool get enableAnalytics => isProduction;

  // Development settings
  static bool get showDebugBanner => kDebugMode;
  static bool get enableMockData => kDebugMode && false; // Disabled by default
}