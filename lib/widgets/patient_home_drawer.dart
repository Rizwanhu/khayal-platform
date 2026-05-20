import 'package:flutter/material.dart';

import '../core/i18n/app_strings.dart';
import '../core/navigation/app_routes.dart';
import '../core/ui/patient_shell_colors.dart';

/// Side menu for the patient dashboard (medicines, map, home area, doctor chat).
///
/// HCI: clear grouping, consistent touch targets, navigator captured before
/// closing drawer so routes still open reliably.
class PatientHomeDrawer extends StatelessWidget {
  const PatientHomeDrawer({super.key});

  void _popThenPush(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: PatientShellColors.canvas,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PatientShellColors.header,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: PatientShellColors.header.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khayal',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'KhayalRoboto',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your care, organised.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'KhayalRoboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text(
                'Shortcuts',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PatientShellColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerNavTile(
                    icon: Icons.medication_outlined,
                    title: AppStrings.myMedicines,
                    subtitle: AppStrings.myMedicinesManage,
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.medicationManagement,
                    ),
                  ),
                  _DrawerNavTile(
                    icon: Icons.map_outlined,
                    title: 'Clinics & hospitals map',
                    subtitle: 'Find care near your saved home',
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.nearbyCareMap);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.home_work_outlined,
                    title: 'Set home area',
                    subtitle: 'Pin where you live on the map',
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.patientHomeArea,
                    ),
                  ),
                  _DrawerNavTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat with my doctor',
                    subtitle: 'Paid monthly · secure messages',
                    onTap: () => _popThenPush(
                      context,
                      AppRoutes.patientDoctorChat,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PatientShellColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _DrawerNavTile(
                icon: Icons.settings_outlined,
                title: AppStrings.settings,
                subtitle: 'Reminders, language & account',
                dense: true,
                onTap: () => _popThenPush(context, AppRoutes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: PatientShellColors.card,
        elevation: 0,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: dense ? 12 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: dense ? 40 : 44,
                  height: dense ? 40 : 44,
                  decoration: BoxDecoration(
                    color: PatientShellColors.header.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: PatientShellColors.header,
                    size: dense ? 22 : 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'KhayalRoboto',
                          color: PatientShellColors.textPrimary,
                          fontSize: dense ? 15 : 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          color: PatientShellColors.textMuted,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: PatientShellColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
