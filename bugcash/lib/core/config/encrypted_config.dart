import 'dart:convert';

class EncryptedConfig {
  // 이 키들은 base64로 인코딩된 암호화된 값들입니다
  // 실제 운영에서는 더 강력한 암호화를 사용하세요
  static const Map<String, String> _encryptedKeys = {
    'firebase_web_api_key': 'eW91cl93ZWJfYXBpX2tleV9oZXJl', // base64 encoded
    'firebase_android_api_key': 'eW91cl9hbmRyb2lkX2FwaV9rZXlfaGVyZQ==',
    'firebase_ios_api_key': 'eW91cl9pb3NfYXBpX2tleV9oZXJl',
    'firebase_macos_api_key': 'eW91cl9tYWNvc19hcGlfa2V5X2hlcmU=',
    'measurement_id': 'Ry1YWFhYWFhYWFhY',
  };

  static String _decrypt(String encryptedValue) {
    try {
      // 간단한 base64 디코딩 (실제로는 더 강력한 암호화 사용)
      return utf8.decode(base64.decode(encryptedValue));
    } catch (e) {
      return 'placeholder_key';
    }
  }

  static String getFirebaseWebApiKey() {
    return _decrypt(_encryptedKeys['firebase_web_api_key']!);
  }

  static String getFirebaseAndroidApiKey() {
    return _decrypt(_encryptedKeys['firebase_android_api_key']!);
  }

  static String getFirebaseIosApiKey() {
    return _decrypt(_encryptedKeys['firebase_ios_api_key']!);
  }

  static String getFirebaseMacosApiKey() {
    return _decrypt(_encryptedKeys['firebase_macos_api_key']!);
  }

  static String getMeasurementId() {
    return _decrypt(_encryptedKeys['measurement_id']!);
  }

  // 개발자가 실제 키를 암호화하는 헬퍼 메서드
  static String encryptKey(String plainKey) {
    return base64.encode(utf8.encode(plainKey));
  }
}