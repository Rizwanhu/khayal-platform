/// In-app dose reminder toggle (patient + caregiver while app is open).
/// Persist with shared_preferences later if needed.
abstract final class ReminderPreferences {
  static bool inAppRemindersEnabled = true;
}
