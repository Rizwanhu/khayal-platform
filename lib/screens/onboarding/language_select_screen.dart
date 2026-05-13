import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../common/widgets/screen_helpers.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-002 · Language Select',
      subtitle: 'Choose your preferred language',
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.roleSelect),
            child: const Text('English'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.roleSelect),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
            ),
            child: const Text('اردو'),
          ),
        ],
      ),
    );
  }
}
