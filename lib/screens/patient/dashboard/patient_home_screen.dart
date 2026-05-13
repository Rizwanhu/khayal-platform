import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/screen_helpers.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-008 · Patient Home',
      subtitle: 'Today\'s medications',
      child: Column(
        children: [
          MedicationCard(
            nameUrdu: 'پیرسٹامول',
            nameEnglish: 'Paracetamol',
            time: '08:00 AM',
            status: 'Upcoming',
            statusColor: AppTheme.upcomingAmber,
          ),
          const SizedBox(height: 10),
          MedicationCard(
            nameUrdu: 'اومیپرازول',
            nameEnglish: 'Omeprazole',
            time: '01:00 PM',
            status: 'Taken',
            statusColor: AppTheme.takenGreen,
          ),
          const SizedBox(height: 14),
          const QuickNavWrap(
            routes: {
              'Dose Confirmation': AppRoutes.doseConfirmation,
              'Medication Detail': AppRoutes.medicationDetail,
              'Patient History': AppRoutes.patientHistory,
              'Settings': AppRoutes.settings,
              'Notification Overlay': AppRoutes.notificationOverlay,
            },
          ),
        ],
      ),
    );
  }
}
