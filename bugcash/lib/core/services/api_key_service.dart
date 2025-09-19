import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _firebaseApiKeyKey = 'firebase_api_key';

  // 환경변수에서 API 키를 로드하는 메서드
  static Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
      if (kDebugMode) {
        print('Environment variables loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not load .env file: $e');
        print('Using fallback configuration');
      }
    }
  }

  // 플랫폼별 Firebase API 키 가져오기
  static Future<String> getFirebaseApiKey() async {
    await loadEnv();

    // 1. SharedPreferences에서 사용자 설정 키 확인
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(_firebaseApiKeyKey);
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }

    // 2. 환경변수에서 플랫폼별 키 로드
    String? envKey;
    if (kIsWeb) {
      envKey = dotenv.env['FIREBASE_WEB_API_KEY'];
    } else {
      // 모바일 플랫폼의 경우 안드로이드 키 사용
      envKey = dotenv.env['FIREBASE_ANDROID_API_KEY'];
    }

    // 3. 환경변수에서 키를 찾을 수 없으면 플레이스홀더 반환
    if (envKey == null || envKey.isEmpty || envKey.contains('your_')) {
      return 'your_firebase_api_key_here';
    }

    return envKey;
  }

  // 특정 플랫폼의 API 키 가져오기
  static Future<String> getFirebaseApiKeyForPlatform(String platform) async {
    await loadEnv();

    final Map<String, String> platformKeys = {
      'web': dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'your_web_api_key_here',
      'android': dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'your_android_api_key_here',
      'ios': dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'your_ios_api_key_here',
      'macos': dotenv.env['FIREBASE_MACOS_API_KEY'] ?? 'your_macos_api_key_here',
    };

    return platformKeys[platform] ?? 'your_firebase_api_key_here';
  }

  // 기타 Firebase 설정값들
  static Future<String> getProjectId() async {
    await loadEnv();
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? 'bugcash';
  }

  static Future<String> getMessagingSenderId() async {
    await loadEnv();
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '335851774651';
  }

  static Future<String> getMeasurementId() async {
    await loadEnv();
    return dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? 'G-XXXXXXXXXX';
  }

  // 사용자 커스텀 API 키 관리 (기존 기능 유지)
  static Future<void> setFirebaseApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firebaseApiKeyKey, apiKey);
  }

  static Future<void> clearFirebaseApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firebaseApiKeyKey);
  }

  static Future<bool> hasCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_firebaseApiKeyKey);
  }

  // 환경변수 로드 상태 확인
  static Future<bool> isEnvLoaded() async {
    try {
      await loadEnv();
      return dotenv.env.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 디버그용: 모든 설정값 출력
  static Future<Map<String, String>> getAllConfig() async {
    await loadEnv();

    return {
      'web_api_key': await getFirebaseApiKeyForPlatform('web'),
      'android_api_key': await getFirebaseApiKeyForPlatform('android'),
      'ios_api_key': await getFirebaseApiKeyForPlatform('ios'),
      'macos_api_key': await getFirebaseApiKeyForPlatform('macos'),
      'project_id': await getProjectId(),
      'messaging_sender_id': await getMessagingSenderId(),
      'measurement_id': await getMeasurementId(),
      'env_loaded': (await isEnvLoaded()).toString(),
      'has_custom_key': (await hasCustomApiKey()).toString(),
    };
  }
}