import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _firebaseApiKeyKey = 'firebase_api_key';
  static const String _defaultApiKey = 'AIzaSyCL7xdDHLHB9CggpjUHQI6mNcKEw_eHGJo';

  static Future<String> getFirebaseApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firebaseApiKeyKey) ?? _defaultApiKey;
  }

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
}