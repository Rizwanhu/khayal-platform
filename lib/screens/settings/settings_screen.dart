import 'package:flutter/material.dart';

import '../../core/auth/auth_logout.dart';
import '../../core/backend/app_session.dart';
import '../../core/backend/backend.dart';
import '../../core/i18n/app_language.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/reminders/dose_alarm_setup_helper.dart';
import '../../core/reminders/medication_notification_service.dart';
import '../../core/reminders/reminder_preferences.dart';
import '../../core/ui/patient_shell_colors.dart';

/// Settings — grouped cards for scanability (HCI: recognition, consistency).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _urdu = AppLanguageState.isUrdu;

  static const _surface = Color(0xFFF3F2EF);

  @override
  Widget build(BuildContext context) {
    final role = AppSession.currentRole;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(
          AppStrings.settings,
          style: const TextStyle(
            fontFamily: 'KhayalRoboto',
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: PatientShellColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: PatientShellColors.divider.withValues(alpha: 0.6),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (role == AppRole.doctor) ...[
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader('Patients'),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.person_add_outlined),
                    title: const Text(
                      'Add patient',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Patient shares a 6-digit code from their home screen (key icon)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'KhayalRoboto',
                        height: 1.35,
                      ),
                    ),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.doctorPatientSetup,
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.people_outline),
                    title: const Text(
                      'My patients',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'View all linked patients',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'KhayalRoboto',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.doctorPatientList);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (role == AppRole.caregiver) ...[
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader('Patient'),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.link_rounded),
                    title: const Text(
                      'Link patient',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Connect using patient phone and link code',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'KhayalRoboto',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.patientProfileSetup);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.notifications_active_outlined),
                    title: const Text(
                      'Reminders & alerts',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'In-app reminders, test alert, today’s dose times',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'KhayalRoboto',
                        height: 1.35,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.caregiverReminders);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(AppStrings.appSection),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  secondary: _LeadingIcon(Icons.notifications_active_outlined),
                  value: ReminderPreferences.inAppRemindersEnabled,
                  onChanged: (v) async {
                    await ReminderPreferences.setEnabled(v);
                    if (!mounted) return;
                    setState(() {});
                    final role = AppSession.currentRole;
                    final uid = AppSession.currentUserId;
                    if (role == AppRole.patient && uid != null && uid.isNotEmpty) {
                      if (v) {
                        final meds =
                            await Backend.repo.getMedicationsForPatient(uid);
                        await MedicationNotificationService.instance.syncSchedules(
                          patientId: uid,
                          meds: meds,
                        );
                      } else {
                        await MedicationNotificationService.instance
                            .cancelAllDoseReminders();
                      }
                    }
                  },
                  title: Text(
                    AppStrings.inAppReminders,
                    style: const TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.inAppRemindersSub,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontFamily: 'KhayalRoboto',
                      height: 1.35,
                    ),
                  ),
                ),
                if (role == AppRole.patient) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.alarm_on_outlined),
                    title: Text(
                      AppLanguageState.pick(
                        en: 'Alarms when app is closed',
                        ur: 'ایپ بند ہونے پر الارم',
                      ),
                      style: const TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      AppLanguageState.pick(
                        en:
                            'Allow exact alarms & turn off battery limit (Infinix: Auto-start)',
                        ur:
                            'Exact alarms اور battery limit بند کریں (Infinix: Auto-start)',
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'KhayalRoboto',
                        height: 1.35,
                      ),
                    ),
                    onTap: () => DoseAlarmSetupHelper.showSetupSheet(context),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  secondary: _LeadingIcon(Icons.translate_rounded),
                  value: _urdu,
                  onChanged: (v) async {
                    setState(() {
                      _urdu = v;
                    });
                    await AppLanguageState.setLanguage(
                      v ? AppLanguage.urdu : AppLanguage.english,
                    );
                    final uid = AppSession.currentUserId;
                    if (uid != null) {
                      await Backend.repo.updateProfileLanguage(
                        userId: uid,
                        languageCode: AppLanguageState.languageCode,
                      );
                    }
                  },
                  title: Text(
                    AppStrings.urduLanguage,
                    style: const TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeader('More'),
                Opacity(
                  opacity: 0.55,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.vibration_rounded, muted: true),
                    title: const Text(
                      'Vibration',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Coming soon — uses system defaults for now',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontSize: 13,
                      ),
                    ),
                    enabled: false,
                  ),
                ),
                const Divider(height: 1),
                Opacity(
                  opacity: 0.55,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: _LeadingIcon(Icons.volume_up_outlined, muted: true),
                    title: const Text(
                      'Reminder sound',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Coming soon — alarm uses your phone’s default',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontSize: 13,
                      ),
                    ),
                    enabled: false,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: _LeadingIcon(Icons.privacy_tip_outlined),
                  title: const Text(
                    'Privacy policy',
                    style: TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Opens in browser when available',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontFamily: 'KhayalRoboto',
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
              title: Text(
                AppLanguageState.pick(
                  en: AppStrings.logOut,
                  ur: 'لاگ آؤٹ',
                ),
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'KhayalRoboto',
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                AppLanguageState.pick(
                  en: AppStrings.logOutSubtitle,
                  ur: 'اس ڈیوائس سے اکاؤنٹ بند کریں',
                ),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontFamily: 'KhayalRoboto',
                  height: 1.35,
                ),
              ),
              onTap: () => AuthLogout.confirmAndSignOut(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PatientShellColors.divider.withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: child,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon, {this.muted = false});

  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: muted
            ? Colors.grey.shade200
            : PatientShellColors.header.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: muted ? Colors.grey.shade600 : PatientShellColors.header,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: PatientShellColors.textMuted,
          fontFamily: 'KhayalRoboto',
          fontSize: 12,
        ),
      ),
    );
  }
}
