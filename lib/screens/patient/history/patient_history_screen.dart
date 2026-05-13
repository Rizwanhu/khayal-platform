import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplate(
      title: 'SCR-011 · Patient History',
      subtitle: 'Last 7 days (frontend sample)',
      child: Column(
        children: [
          HistoryRow(day: 'Monday', status: 'Taken'),
          HistoryRow(day: 'Tuesday', status: 'Taken'),
          HistoryRow(day: 'Wednesday', status: 'Missed'),
          HistoryRow(day: 'Thursday', status: 'Taken'),
          HistoryRow(day: 'Friday', status: 'Upcoming'),
        ],
      ),
    );
  }
}
