import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class DoseConfirmationScreen extends StatelessWidget {
  const DoseConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-009 · Dose Confirmation',
      subtitle: 'Confirm dose action',
      child: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Paracetamol 500mg · 08:00 AM'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Mark as Taken')),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Remind me in 15 min'),
          ),
        ],
      ),
    );
  }
}
