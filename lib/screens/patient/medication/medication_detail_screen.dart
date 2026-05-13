import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplate(
      title: 'SCR-010 · Medication Detail',
      subtitle: 'Detailed medication view',
      child: Column(
        children: [
          InfoTile(label: 'Urdu Name', value: 'پیرسٹامول'),
          InfoTile(label: 'English Name', value: 'Paracetamol'),
          InfoTile(label: 'Dose', value: '500 mg'),
          InfoTile(label: 'Frequency', value: 'Twice Daily'),
          InfoTile(label: 'Time', value: '08:00 AM, 08:00 PM'),
        ],
      ),
    );
  }
}
