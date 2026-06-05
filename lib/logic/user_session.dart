import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserSession {

  static Future<String> _getPrefix() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return "${user.uid}_";
        }
      }
    } catch (e) {
      // Fallback for tests or uninitialized state
      return "";
    }
    return ""; // Guest or fallback
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    await prefs.setString('$prefix$key', value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    return prefs.getString('$prefix$key');
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    await prefs.setBool('$prefix$key', value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    return prefs.getBool('$prefix$key');
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    await prefs.setInt('$prefix$key', value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = await _getPrefix();
    return prefs.getInt('$prefix$key');
  }

  // --- Session Management ---

  static Future<String> getUserName() async {
    String? name = await getString('user_name');
    if (name == null || name.isEmpty) {
      // Fallback to global if missing (migration)
      final prefs = await SharedPreferences.getInstance();
      name = prefs.getString('user_name');
    }
    return name ?? "User";
  }

  static Future<String> getUserDob() async {
    String? dob = await getString('user_dob');
    if (dob == null) {
       final prefs = await SharedPreferences.getInstance();
       dob = prefs.getString('user_dob');
    }
    return dob ?? DateTime.now().toIso8601String();
  }

  static Future<String?> getProfileImage() async {
    return await getString('profile_image_base64');
  }

  static Future<String?> getProfileImageUrl() async {
    return await getString('profile_image_url');
  }

  /// Removes a key from the per-user prefs (used when migrating away from
  /// the legacy base64 profile image).
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = await _getPrefix();
    await prefs.remove('$prefix$key');
  }

  static Future<String?> getUserLanguage() async {
    return await getString('user_language');
  }

  static Future<void> setUserLanguage(String languageCode) async {
    await setString('user_language', languageCode);
  }

  static Future<void> clearSession() async {
    // We do NOT clear SharedPreferences entirely, only the 'current' pointers if any.
    // But since we use prefixes, logging out essentially switches the prefix to "" (guest).
    // The prefix logic handles the isolation.
  }
}
