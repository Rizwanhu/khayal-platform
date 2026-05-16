enum AppRole { patient, caregiver, doctor }

/// Payload for [DoseReminderPanel] / notification overlay when opened from a real med.
class PendingDoseReminder {
  const PendingDoseReminder({
    required this.medicationId,
    required this.nameEn,
    required this.nameUr,
    required this.timeDisplay,
    required this.doseUr,
    this.scheduleRaw,
    this.imageStoragePath,
  });

  final String medicationId;
  final String nameEn;
  final String nameUr;
  final String timeDisplay;
  final String doseUr;

  /// DB `local_time` for today's dose log, e.g. `08:30:00`.
  final String? scheduleRaw;

  /// Storage path in `medication-photos` bucket.
  final String? imageStoragePath;
}

abstract final class AppSession {
  static AppRole? currentRole;
  static String? currentUserId;
  static String? selectedPatientId;

  /// When set, reminder UIs read this instead of placeholder copy.
  static PendingDoseReminder? pendingDoseReminder;

  static void clearPendingDoseReminder() {
    pendingDoseReminder = null;
  }

  static void setPendingRole(AppRole role) {
    currentRole = role;
  }

  static void setRole({
    required AppRole role,
    required String userId,
    String? patientId,
  }) {
    currentRole = role;
    currentUserId = userId;
    selectedPatientId = patientId;
  }
}
