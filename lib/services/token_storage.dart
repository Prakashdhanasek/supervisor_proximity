import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';

  static Future<void> save(String token, {String? fullName, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    if (fullName != null) await prefs.setString(_nameKey, fullName);
    if (email != null) await prefs.setString(_emailKey, email);
  }

  static Future<Map<String, String?>> get() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_key),
      'fullName': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }
}
