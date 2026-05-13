import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../common/widgets/screen_helpers.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-003 · Role Select',
      subtitle: 'Select how you want to continue',
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.patientHome),
            icon: const Icon(Icons.person),
            label: const Text('Continue as Patient'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                () =>
                    Navigator.pushNamed(context, AppRoutes.caregiverDashboard),
            icon: const Icon(Icons.people),
            label: const Text('Continue as Caregiver'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.doctorDashboard),
            icon: const Icon(Icons.medical_services),
            label: const Text('Continue as Doctor'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.caregiverRegistration,
                ),
            child: const Text('Open Caregiver Registration'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.otpLink),
            child: const Text('Open OTP Link Screen'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
