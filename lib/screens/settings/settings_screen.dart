import 'package:flutter/material.dart';

import '../common/widgets/screen_helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-016 · Settings',
      subtitle: 'Preferences and app options',
      child: Column(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Urdu Language'),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Vibration'),
          ),
          const ListTile(
            title: Text('Reminder Sound'),
            subtitle: Text('Sound 1 (sample)'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }
}
