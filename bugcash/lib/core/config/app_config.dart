import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      if (kDebugMode) {
        print('Warning: .env file not found. Using default configuration.');
      }
    }
  }

  // Firebase Configuration
  static String get firebaseApiKey => 
      dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyA0hLevMSRKZpoMaF4Sb_YgvR7ED1VR6Xo';
  
  static String get firebaseProjectId => 
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'bugcash';
  
  static String get firebaseMessagingSenderId => 
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '335851774651';
  
  static String get firebaseAppId => 
      dotenv.env['FIREBASE_APP_ID'] ?? '1:335851774651:android:9c485dd2a5f436ef0abf9e';
  
  static String get firebaseStorageBucket => 
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'bugcash.firebasestorage.app';
  
  static String get firebaseAuthDomain => 
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'bugcash.firebaseapp.com';
  
  static String get firebaseMeasurementId => 
      dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  // App Configuration
  static bool get isProduction => kReleaseMode;
  static bool get enableLogging => !isProduction && kDebugMode;
}