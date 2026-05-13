import 'package:flutter/material.dart';

import '../../common/widgets/screen_helpers.dart';

class DoctorPatientHistoryScreen extends StatelessWidget {
  const DoctorPatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplate(
      title: 'Doctor Patient History',
      subtitle: 'Read-only adherence and dose history',
      child: Column(
        children: [
          InfoTile(label: 'Patient', value: 'Muhammad Ali'),
          InfoTile(label: 'Weekly Adherence', value: '81%'),
          SizedBox(height: 10),
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
