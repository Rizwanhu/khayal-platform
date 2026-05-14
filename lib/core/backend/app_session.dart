enum AppRole { patient, caregiver, doctor }

abstract final class AppSession {
  static AppRole? currentRole;
  static String? currentUserId;
  static String? selectedPatientId;

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
