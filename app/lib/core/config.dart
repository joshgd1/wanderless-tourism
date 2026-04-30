import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _baseUrlKey = 'api_base_url';
  static const String defaultUrl = 'http://10.0.2.2:8000/api';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }
}
