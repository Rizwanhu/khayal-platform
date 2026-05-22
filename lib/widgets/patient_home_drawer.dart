import 'package:flutter/material.dart';

import '../core/i18n/app_language.dart';
import '../core/i18n/app_strings.dart';
import '../core/navigation/app_routes.dart';
import '../core/ui/patient_shell_colors.dart';
import '../core/ui/patient_ui_tokens.dart';
import '../core/ui/patient_ui_widgets.dart';

/// Side menu — large tap targets and plain labels for older patients.
class PatientHomeDrawer extends StatelessWidget {
  const PatientHomeDrawer({super.key});

  void _popThenPush(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      backgroundColor: PatientShellColors.canvas,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PatientUiTokens.paddingScreen,
                16,
                PatientUiTokens.paddingScreen,
                12,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PatientShellColors.header,
                  borderRadius: BorderRadius.circular(PatientUiTokens.radiusCard),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(PatientUiTokens.paddingCard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khayal',
                        style: PatientUiTokens.titleLargeStyle(
                          urdu: false,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLanguageState.pick(
                          en: 'Tap a button below to open that page.',
                          ur: 'نیچے بٹن دبائیں — وہ صفحہ کھل جائے گا۔',
                        ),
                        style: PatientUiTokens.bodySmallStyle(
                          urdu: AppLanguageState.isUrdu,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: PatientUi.sectionLabel(
                AppLanguageState.pick(en: 'Main menu', ur: 'مین مینو'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  PatientUi.navTile(
                    icon: Icons.medication_outlined,
                    title: AppStrings.myMedicines,
                    subtitle: AppLanguageState.pick(
                      en: 'Add or change your medicines',
                      ur: 'دوائیں شامل یا تبدیل کریں',
                    ),
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.medicationManagement,
                    ),
                  ),
                  PatientUi.navTile(
                    icon: Icons.map_outlined,
                    title: AppLanguageState.pick(
                      en: 'Hospitals & clinics map',
                      ur: 'ہسپتال اور کلینک نقشہ',
                    ),
                    subtitle: AppLanguageState.pick(
                      en: 'Find care near your home',
                      ur: 'گھر کے قریب علاج تلاش کریں',
                    ),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.nearbyCareMap);
                    },
                  ),
                  PatientUi.navTile(
                    icon: Icons.home_work_outlined,
                    title: AppLanguageState.pick(
                      en: 'Set home on map',
                      ur: 'گھر کا مقام',
                    ),
                    subtitle: AppLanguageState.pick(
                      en: 'Where you live — for nearby search',
                      ur: 'آپ کہاں رہتے ہیں',
                    ),
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.patientHomeArea,
                    ),
                  ),
                  PatientUi.navTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppLanguageState.pick(
                      en: 'Message my doctor',
                      ur: 'ڈاکٹر سے بات',
                    ),
                    subtitle: AppLanguageState.pick(
                      en: 'Paid monthly · private chat',
                      ur: 'ماہانہ فیس · محفوظ چیٹ',
                    ),
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.patientDoctorChat,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: PatientShellColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: PatientUi.navTile(
                icon: Icons.settings_outlined,
                title: AppStrings.settings,
                subtitle: AppLanguageState.pick(
                  en: 'Reminders, language, sign out',
                  ur: 'الرٹ، زبان، لاگ آؤٹ',
                ),
                onTap: () => _popThenPush(context, AppRoutes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
