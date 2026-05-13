import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class CaregiverRegistrationScreen extends StatelessWidget {
  const CaregiverRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScreen(
      title: 'SCR-004 · Caregiver Registration',
      fields: const ['Full Name', 'Phone Number', 'Relationship'],
      nextLabel: 'Continue to Patient Profile Setup',
      onNext: () => Navigator.pushNamed(context, AppRoutes.patientProfileSetup),
    );
  }
}
