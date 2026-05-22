import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, urdu }

/// In-app locale (English / Urdu). Persists locally and syncs to profile on sign-in.
abstract final class AppLanguageState {
  static const _prefsKey = 'khayal_app_language';

  static AppLanguage current = AppLanguage.english;

  static final ValueNotifier<int> localeRevision = ValueNotifier<int>(0);

  static bool get isUrdu => current == AppLanguage.urdu;

  static String get languageCode => isUrdu ? 'ur' : 'en';

  static String pick({required String en, required String ur}) {
    return isUrdu ? ur : en;
  }

  static Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == 'ur') {
      current = AppLanguage.urdu;
    } else if (stored == 'en') {
      current = AppLanguage.english;
    }
    localeRevision.value++;
  }

  static Future<void> setLanguage(AppLanguage language) async {
    current = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      language == AppLanguage.urdu ? 'ur' : 'en',
    );
    localeRevision.value++;
  }

  static void applyLanguageCode(String? code) {
    final c = (code ?? 'en').trim().toLowerCase();
    current = c == 'ur' || c.startsWith('ur') ? AppLanguage.urdu : AppLanguage.english;
    localeRevision.value++;
  }
}
