import 'package:shared_preferences/shared_preferences.dart';

/// Stores only the "remember me" choice and the email. Never the password.
class RememberMeService {
  static const _rememberKey = 'remember_me';
  static const _emailKey = 'remembered_email';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<String?> savedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<void> save({required bool remember, String email = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    if (remember && email.isNotEmpty) {
      await prefs.setString(_emailKey, email);
    } else if (!remember) {
      await prefs.remove(_emailKey);
    }
  }
}