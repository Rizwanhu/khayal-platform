import 'package:flutter/material.dart';

import '../../screens/caregiver/auth/caregiver_registration_screen.dart';
import '../../screens/caregiver/auth/patient_profile_setup_screen.dart';
import '../../screens/caregiver/dashboard/caregiver_dashboard_screen.dart';
import '../../screens/caregiver/history/alert_history_screen.dart';
import '../../screens/caregiver/medication/add_medication_screen.dart';
import '../../screens/caregiver/medication/edit_medication_screen.dart';
import '../../screens/caregiver/medication/medication_management_screen.dart';
import '../../screens/caregiver/reminders/caregiver_reminders_screen.dart';
import '../../core/backend/backend_repository.dart';
import '../../screens/doctor/auth/doctor_patient_setup_screen.dart';
import '../../screens/doctor/dashboard/doctor_dashboard_screen.dart';
import '../../screens/doctor/history/doctor_patient_history_screen.dart';
import '../../screens/doctor/patients/doctor_patient_list_screen.dart';
import '../../screens/onboarding/language_select_screen.dart';
import '../../screens/onboarding/otp_link_screen.dart';
import '../../screens/onboarding/profile_registration_screen.dart';
import '../../screens/onboarding/role_select_screen.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../screens/patient/dashboard/patient_home_screen.dart';
import '../../screens/patient/history/patient_history_screen.dart';
import '../../screens/patient/medication/dose_confirmation_screen.dart';
import '../../screens/patient/medication/dose_taken_success_screen.dart';
import '../../screens/patient/medication/medication_detail_screen.dart';
import '../../screens/patient/maps/nearby_care_map_screen.dart';
import '../../screens/patient/maps/patient_home_area_screen.dart';
import '../../screens/patient/chat/patient_doctor_chat_screen.dart';
import '../../screens/patient/notification/notification_overlay_screen.dart';
import '../../screens/doctor/chat/doctor_patient_chat_screen.dart';
import '../../screens/settings/settings_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const languageSelect = '/language-select';
  static const roleSelect = '/role-select';
  static const caregiverRegistration = '/caregiver-registration';
  static const profileRegistration = '/profile-registration';
  static const patientProfileSetup = '/patient-profile-setup';
  static const addMedication = '/add-medication';
  static const otpLink = '/otp-link';
  static const patientHome = '/patient-home';
  static const doseConfirmation = '/dose-confirmation';
  static const doseTakenSuccess = '/dose-taken-success';
  static const medicationDetail = '/medication-detail';
  static const patientHistory = '/patient-history';
  static const caregiverDashboard = '/caregiver-dashboard';
  static const medicationManagement = '/medication-management';
  static const editMedication = '/edit-medication';
  static const alertHistory = '/alert-history';
  static const caregiverReminders = '/caregiver-reminders';
  static const doctorDashboard = '/doctor-dashboard';
  static const doctorPatientSetup = '/doctor-patient-setup';
  static const doctorPatientList = '/doctor-patient-list';
  static const doctorPatientHistory = '/doctor-patient-history';
  static const settings = '/settings';
  static const notificationOverlay = '/notification-overlay';
  static const patientHomeArea = '/patient-home-area';
  static const nearbyCareMap = '/nearby-care-map';
  static const patientDoctorChat = '/patient-doctor-chat';
  static const doctorPatientChat = '/doctor-patient-chat';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.splash: (_) => const SplashScreen(),
  AppRoutes.languageSelect: (_) => const LanguageSelectScreen(),
  AppRoutes.roleSelect: (_) => const RoleSelectScreen(),
  AppRoutes.caregiverRegistration: (_) => const CaregiverRegistrationScreen(),
  AppRoutes.profileRegistration: (_) => const ProfileRegistrationScreen(),
  AppRoutes.patientProfileSetup: (_) => const PatientProfileSetupScreen(),
  AppRoutes.addMedication: (_) => const AddMedicationScreen(),
  AppRoutes.otpLink: (_) => const OtpLinkScreen(),
  AppRoutes.patientHome: (_) => const PatientHomeScreen(),
  AppRoutes.doseConfirmation: (_) => const DoseConfirmationScreen(),
  AppRoutes.doseTakenSuccess: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final summary = args is TodayDoseSummary ? args : null;
    return DoseTakenSuccessScreen(
      takenCount: summary?.taken ?? 0,
      totalCount: summary?.total ?? 0,
    );
  },
  AppRoutes.medicationDetail: (context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    return MedicationDetailScreen(medicationId: id);
  },
  AppRoutes.patientHistory: (_) => const PatientHistoryScreen(),
  AppRoutes.caregiverDashboard: (_) => const CaregiverDashboardScreen(),
  AppRoutes.medicationManagement: (_) => const MedicationManagementScreen(),
  AppRoutes.editMedication: (_) => const EditMedicationScreen(),
  AppRoutes.alertHistory: (_) => const AlertHistoryScreen(),
  AppRoutes.caregiverReminders: (_) => const CaregiverRemindersScreen(),
  AppRoutes.doctorDashboard: (_) => const DoctorDashboardScreen(),
  AppRoutes.doctorPatientSetup: (_) => const DoctorPatientSetupScreen(),
  AppRoutes.doctorPatientList: (_) => const DoctorPatientListScreen(),
  AppRoutes.doctorPatientHistory: (_) => const DoctorPatientHistoryScreen(),
  AppRoutes.settings: (_) => const SettingsScreen(),
  AppRoutes.notificationOverlay: (_) => const NotificationOverlayScreen(),
  AppRoutes.patientHomeArea: (_) => const PatientHomeAreaScreen(),
  AppRoutes.nearbyCareMap: (_) => const NearbyCareMapScreen(),
  AppRoutes.patientDoctorChat: (_) => const PatientDoctorChatScreen(),
  AppRoutes.doctorPatientChat: (context) {
    final patientId = ModalRoute.of(context)?.settings.arguments as String?;
    return DoctorPatientChatScreen(patientId: patientId);
  },
};
