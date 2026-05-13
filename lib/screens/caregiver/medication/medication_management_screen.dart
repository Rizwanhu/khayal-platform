import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class MedicationManagementScreen extends StatelessWidget {
  const MedicationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-013 · Medication Management',
      subtitle: 'Manage all active medications',
      child: Column(
        children: [
          MedicationCard(
            nameUrdu: 'پیرسٹامول',
            nameEnglish: 'Paracetamol',
            time: '08:00 AM',
            status: 'Active',
            statusColor: Colors.green.shade700,
          ),
          const SizedBox(height: 10),
          MedicationCard(
            nameUrdu: 'اومیپرازول',
            nameEnglish: 'Omeprazole',
            time: '01:00 PM',
            status: 'Active',
            statusColor: Colors.green.shade700,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.editMedication),
            child: const Text('Edit Selected Medication'),
          ),
        ],
      ),
    );
  }
}
