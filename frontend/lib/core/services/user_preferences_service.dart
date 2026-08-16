import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _userNameKey = 'user_name';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  static Future<void> saveUserName(String name) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _userNameKey,
      name.trim(),
    );
  }

  static Future<String?> getUserName() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_userNameKey);
  }

  static Future<void> setOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _onboardingCompletedKey,
      true,
    );
  }

  static Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }
}