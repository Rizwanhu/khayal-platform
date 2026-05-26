import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../core/ui/doctor_shell_colors.dart';
import '../core/ui/doctor_ui_tokens.dart';
import '../core/ui/doctor_ui_widgets.dart';

/// Side menu for the doctor portal — replaces plain text chips on the dashboard.
class DoctorShellDrawer extends StatelessWidget {
  const DoctorShellDrawer({super.key, this.currentRoute});

  /// Highlights the active item when it matches [currentRoute].
  final String? currentRoute;

  void _popThenPush(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (ModalRoute.of(context)?.settings.name == routeName) return;
    navigator.pushNamed(routeName);
  }

  void _popOnly(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.86,
      backgroundColor: DoctorShellColors.canvas,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DoctorUiTokens.paddingScreen,
                16,
                DoctorUiTokens.paddingScreen,
                12,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DoctorShellColors.header,
                  borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(DoctorUiTokens.paddingCard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khayal · Doctor',
                        style: TextStyle(
                          fontFamily: 'KhayalRoboto',
                          fontSize: DoctorUiTokens.titleMedium,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Open a section below. Your patients stay on the dashboard.',
                        style: TextStyle(
                          fontFamily: 'KhayalRoboto',
                          fontSize: DoctorUiTokens.bodySmall,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: DoctorUi.sectionLabel('Menu'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  DoctorUi.navTile(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    subtitle: 'Overview & patient list',
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (currentRoute != AppRoutes.doctorDashboard) {
                        navigator.pushReplacementNamed(
                          AppRoutes.doctorDashboard,
                        );
                      }
                    },
                  ),
                  DoctorUi.navTile(
                    icon: Icons.people_outline_rounded,
                    title: 'All patients',
                    subtitle: 'Linked accounts & messaging',
                    onTap: () => _popThenPush(context, AppRoutes.doctorPatientList),
                  ),
                  DoctorUi.navTile(
                    icon: Icons.history_rounded,
                    title: 'Dose history',
                    subtitle: 'Adherence for selected patient',
                    onTap: () =>
                        _popThenPush(context, AppRoutes.doctorPatientHistory),
                  ),
                  DoctorUi.navTile(
                    icon: Icons.link_rounded,
                    title: 'Link new patient',
                    subtitle: 'Phone + 6-digit code from patient app',
                    onTap: () =>
                        _popThenPush(context, AppRoutes.doctorPatientSetup),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DoctorShellColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: DoctorUi.navTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account & sign out',
                onTap: () => _popThenPush(context, AppRoutes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
