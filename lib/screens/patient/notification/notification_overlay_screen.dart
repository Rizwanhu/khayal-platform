import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class NotificationOverlayScreen extends StatelessWidget {
  const NotificationOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-017 · Notification Overlay',
      subtitle: 'Reminder mock UI',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notifications_active_rounded),
                title: Text('Time to take Paracetamol'),
                subtitle: Text('Dose: 500mg · Scheduled: 08:00 AM'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () {}, child: const Text('Taken')),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Remind me in 15 min'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
