import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class PatientProfileSetupScreen extends StatelessWidget {
  const PatientProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'SCR-005 · Patient Profile Setup',
      fields: const ['Patient Name (Urdu)', 'Patient Name (English)', 'Age'],
      nextLabel: 'Continue to Add Medication',
      onNext: () => Navigator.pushNamed(context, AppRoutes.addMedication),
    );
  }
}
