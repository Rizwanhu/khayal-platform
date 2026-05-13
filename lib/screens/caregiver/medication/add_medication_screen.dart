import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class AddMedicationScreen extends StatelessWidget {
  const AddMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'SCR-006 · Add Medication',
      fields: const [
        'Medicine Name (Urdu)',
        'Medicine Name (English)',
        'Dose & Unit',
        'Frequency',
        'Time',
      ],
      nextLabel: 'Save (Frontend Demo)',
      onNext:
          () => Navigator.pushNamed(context, AppRoutes.medicationManagement),
    );
  }
}
