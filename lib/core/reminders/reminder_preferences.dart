import 'package:shared_preferences/shared_preferences.dart';

/// Dose reminders: in-app overlay + OS notifications (when enabled).
abstract final class ReminderPreferences {
  static const _keyEnabled = 'dose_reminders_enabled';

  static bool inAppRemindersEnabled = true;

  static Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    inAppRemindersEnabled = prefs.getBool(_keyEnabled) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    inAppRemindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }
}
