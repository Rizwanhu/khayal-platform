import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-012 · Caregiver Dashboard',
      subtitle: 'Overview for linked patient',
      child: Column(
        children: [
          const InfoTile(label: 'Patient', value: 'Muhammad Ali'),
          const InfoTile(label: 'Today Adherence', value: '66%'),
          const InfoTile(label: 'Missed Doses', value: '1'),
          const SizedBox(height: 14),
          const QuickNavWrap(
            routes: {
              'Medication Management': AppRoutes.medicationManagement,
              'Edit Medication': AppRoutes.editMedication,
              'Alert History': AppRoutes.alertHistory,
              'Add Medication': AppRoutes.addMedication,
              'Settings': AppRoutes.settings,
            },
          ),
        ],
      ),
    );
  }
}
