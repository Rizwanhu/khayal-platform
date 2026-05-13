import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../common/widgets/screen_helpers.dart';

class OtpLinkScreen extends StatelessWidget {
  const OtpLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-007 · OTP Link',
      subtitle: 'Enter 6-digit code to link patient and caregiver',
      child: Column(
        children: [
          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '123456',
              labelText: 'OTP Code',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.patientHome),
            child: const Text('Verify & Open Patient Home'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed:
                () =>
                    Navigator.pushNamed(context, AppRoutes.caregiverDashboard),
            child: const Text('Verify & Open Caregiver Dashboard'),
          ),
        ],
      ),
    );
  }
}
