enum AppLanguage { english, urdu }

abstract final class AppLanguageState {
  static AppLanguage current = AppLanguage.english;

  static void setLanguage(AppLanguage language) {
    current = language;
  }

  static bool get isUrdu => current == AppLanguage.urdu;

  static String pick({required String en, required String ur}) {
    return isUrdu ? ur : en;
  }
}
