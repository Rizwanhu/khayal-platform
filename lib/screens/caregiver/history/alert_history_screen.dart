import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplate(
      title: 'SCR-015 · Alert History',
      subtitle: 'Missed dose alerts log',
      child: Column(
        children: [
          InfoTile(label: '08:30 AM', value: 'Paracetamol missed'),
          InfoTile(label: '01:35 PM', value: 'Omeprazole missed'),
          InfoTile(label: '08:45 PM', value: 'Calcium dose delayed'),
        ],
      ),
    );
  }
}
