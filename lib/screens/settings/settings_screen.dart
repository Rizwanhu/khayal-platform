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

/// Simple settings — options depend on logged-in role.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _urdu = AppLanguageState.isUrdu;

  @override
  Widget build(BuildContext context) {
    final role = AppSession.currentRole;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings)),
      body: ListView(
        children: [
          if (role == AppRole.doctor) ...[
            const _SectionHeader('Patients'),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Add patient'),
              subtitle: const Text(
                'Patient shares a 6-digit code from their home screen (key icon)',
              ),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.doctorPatientSetup,
                );
                if (mounted) setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('My patients'),
              subtitle: const Text('View all linked patients'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.doctorPatientList);
              },
            ),
            const Divider(),
          ],
          if (role == AppRole.caregiver) ...[
            const _SectionHeader('Patient'),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Link patient'),
              subtitle: const Text('Connect using patient phone and link code'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.patientProfileSetup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Reminders & alerts'),
              subtitle: const Text(
                'In-app reminders, test alert, today’s dose times',
              ),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.caregiverReminders);
              },
            ),
            const Divider(),
          ],
          _SectionHeader(AppStrings.appSection),
          SwitchListTile(
            value: ReminderPreferences.inAppRemindersEnabled,
            onChanged: (v) async {
              await ReminderPreferences.setEnabled(v);
              if (!mounted) return;
              setState(() {});
              final role = AppSession.currentRole;
              final uid = AppSession.currentUserId;
              if (role == AppRole.patient && uid != null && uid.isNotEmpty) {
                if (v) {
                  final meds = await Backend.repo.getMedicationsForPatient(uid);
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
            title: Text(AppStrings.inAppReminders),
            subtitle: Text(AppStrings.inAppRemindersSub),
          ),
          if (role == AppRole.patient)
            ListTile(
              leading: const Icon(Icons.alarm_on_outlined),
              title: Text(
                AppLanguageState.pick(
                  en: 'Alarms when app is closed',
                  ur: 'ایپ بند ہونے پر الارم',
                ),
              ),
              subtitle: Text(
                AppLanguageState.pick(
                  en: 'Allow exact alarms & turn off battery limit (Infinix: Auto-start)',
                  ur: 'Exact alarms اور battery limit بند کریں (Infinix: Auto-start)',
                ),
              ),
              onTap: () => DoseAlarmSetupHelper.showSetupSheet(context),
            ),
          SwitchListTile(
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
            title: Text(AppStrings.urduLanguage),
          ),
          const ListTile(
            leading: Icon(Icons.vibration),
            title: Text('Vibration'),
            subtitle: Text('On'),
          ),
          const ListTile(
            leading: Icon(Icons.volume_up_outlined),
            title: Text('Reminder sound'),
            subtitle: Text('Default'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy policy'),
            trailing: Icon(Icons.open_in_new, size: 20),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
            title: Text(
              AppLanguageState.pick(
                en: AppStrings.logOut,
                ur: 'لاگ آؤٹ',
              ),
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              AppLanguageState.pick(
                en: AppStrings.logOutSubtitle,
                ur: 'اس ڈیوائس سے اکاؤنٹ بند کریں',
              ),
            ),
            onTap: () => AuthLogout.confirmAndSignOut(context),
          ),
          const SizedBox(height: 24),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}
