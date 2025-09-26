import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static final StorageHelper _instance = StorageHelper._internal();
  factory StorageHelper() => _instance;
  StorageHelper._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyIsPremiumUser = 'is_premium_user';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAppTheme = 'app_theme';
  static const String _keyLanguage = 'language';

  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<bool> setOnboardingCompleted(bool value) {
    return _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool isPremiumUser() {
    return _prefs.getBool(_keyIsPremiumUser) ?? false;
  }

  Future<bool> setPremiumUser(bool value) {
    return _prefs.setBool(_keyIsPremiumUser, value);
  }

  String? getUserName() {
    return _prefs.getString(_keyUserName);
  }

  Future<bool> setUserName(String value) {
    return _prefs.setString(_keyUserName, value);
  }

  String? getUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  Future<bool> setUserEmail(String value) {
    return _prefs.setString(_keyUserEmail, value);
  }

  String getAppTheme() {
    return _prefs.getString(_keyAppTheme) ?? 'light';
  }

  Future<bool> setAppTheme(String value) {
    return _prefs.setString(_keyAppTheme, value);
  }

  String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? 'en';
  }

  Future<bool> setLanguage(String value) {
    return _prefs.setString(_keyLanguage, value);
  }

  Future<bool> clearAll() {
    return _prefs.clear();
  }
}