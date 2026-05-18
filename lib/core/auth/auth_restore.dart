import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_session.dart';
import '../backend/backend.dart';
import '../i18n/app_language.dart';
import '../navigation/app_routes.dart';
import '../reminders/medication_notification_service.dart';
import 'auth_session_store.dart';
import '../reminders/medication_alarm_scheduler.dart';

/// Restores [AppSession] and navigates to the correct home after a valid Supabase session.
abstract final class AuthRestore {
  static Future<void> navigateAfterSignIn(
    BuildContext context, {
    required User user,
    required AppRole role,
  }) async {
    await AuthSessionStore.saveRole(role);

    final profile = await Backend.repo.getPatientProfile(user.id);
    final storedLang = profile?.languageCode?.trim();
    if (storedLang != null && storedLang.isNotEmpty) {
      await AppLanguageState.setLanguage(
        storedLang == 'ur' || storedLang.startsWith('ur')
            ? AppLanguage.urdu
            : AppLanguage.english,
      );
    }

    AppSession.setRole(
      role: role,
      userId: user.id,
      patientId: role == AppRole.patient ? user.id : null,
    );

    if (!context.mounted) return;

    switch (role) {
      case AppRole.patient:
        final patientProfileDone = await Backend.repo.patientProfileIsComplete(
          user.id,
        );
        if (!context.mounted) return;
        if (!patientProfileDone) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.profileRegistration,
            (route) => false,
          );
          return;
        }
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.patientHome,
          (route) => false,
        );
        await _primePatientNotifications(user.id);
        await MedicationAlarmScheduler.instance.refreshForCurrentPatient();
        break;
      case AppRole.caregiver:
        final profileDone = await Backend.repo.caregiverProfileIsComplete(
          user.id,
        );
        if (!context.mounted) return;
        final linkedPatientId =
            profileDone
                ? await Backend.repo.getFirstPatientForCaregiver(user.id)
                : null;
        if (!context.mounted) return;
        AppSession.setRole(
          role: AppRole.caregiver,
          userId: user.id,
          patientId: linkedPatientId,
        );
        final caregiverRoute =
            !profileDone
                ? AppRoutes.caregiverRegistration
                : (linkedPatientId != null
                    ? AppRoutes.caregiverDashboard
                    : AppRoutes.patientProfileSetup);
        Navigator.pushNamedAndRemoveUntil(
          context,
          caregiverRoute,
          (route) => false,
        );
        break;
      case AppRole.doctor:
        final doctorProfileDone = await Backend.repo.doctorProfileIsComplete(
          user.id,
        );
        if (!context.mounted) return;
        if (!doctorProfileDone) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.profileRegistration,
            (route) => false,
          );
          return;
        }
        final linkedPatientId = await Backend.repo.getFirstPatientForDoctor(
          user.id,
        );
        if (!context.mounted) return;
        AppSession.setRole(
          role: AppRole.doctor,
          userId: user.id,
          patientId: linkedPatientId,
        );
        final doctorRoute =
            linkedPatientId != null
                ? AppRoutes.doctorDashboard
                : AppRoutes.doctorPatientSetup;
        Navigator.pushNamedAndRemoveUntil(
          context,
          doctorRoute,
          (route) => false,
        );
        break;
    }
  }

  static Future<void> _primePatientNotifications(String patientId) async {
    try {
      final meds = await Backend.repo.getMedicationsForPatient(patientId);
      await MedicationNotificationService.instance.syncSchedules(
        patientId: patientId,
        meds: meds,
      );
    } catch (_) {}
  }

  /// Returns route to open from splash, or null to continue normal first-time onboarding.
  static Future<String?> routeForRestoredSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final user = session.user;
    var role = await AuthSessionStore.loadRole();
    final profile = await Backend.repo.getPatientProfile(user.id);
    role ??= _roleFromProfile(profile?.role);

    if (role == null) return null;

    AppSession.setRole(
      role: role,
      userId: user.id,
      patientId: role == AppRole.patient ? user.id : null,
    );

    switch (role) {
      case AppRole.patient:
        if (!await Backend.repo.patientProfileIsComplete(user.id)) {
          return AppRoutes.profileRegistration;
        }
        await _primePatientNotifications(user.id);
        await MedicationAlarmScheduler.instance.refreshForCurrentPatient();
        return AppRoutes.patientHome;
      case AppRole.caregiver:
        if (!await Backend.repo.caregiverProfileIsComplete(user.id)) {
          return AppRoutes.caregiverRegistration;
        }
        final linked = await Backend.repo.getFirstPatientForCaregiver(user.id);
        AppSession.selectedPatientId = linked;
        return linked != null
            ? AppRoutes.caregiverDashboard
            : AppRoutes.patientProfileSetup;
      case AppRole.doctor:
        if (!await Backend.repo.doctorProfileIsComplete(user.id)) {
          return AppRoutes.profileRegistration;
        }
        final linked = await Backend.repo.getFirstPatientForDoctor(user.id);
        AppSession.selectedPatientId = linked;
        return linked != null
            ? AppRoutes.doctorDashboard
            : AppRoutes.doctorPatientSetup;
    }
  }

  static AppRole? _roleFromProfile(String? roleRaw) {
    return switch (roleRaw?.toLowerCase()) {
      'patient' => AppRole.patient,
      'caregiver' => AppRole.caregiver,
      'doctor' => AppRole.doctor,
      _ => null,
    };
  }
}
