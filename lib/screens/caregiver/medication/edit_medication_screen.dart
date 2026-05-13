import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class EditMedicationScreen extends StatelessWidget {
  const EditMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'SCR-014 · Edit Medication',
      fields: const [
        'Medicine Name (Urdu)',
        'Medicine Name (English)',
        'Dose & Unit',
        'Frequency',
        'Time',
      ],
      nextLabel: 'Update (Frontend Demo)',
      onNext:
          () => Navigator.pushNamed(context, AppRoutes.medicationManagement),
    );
  }
}
