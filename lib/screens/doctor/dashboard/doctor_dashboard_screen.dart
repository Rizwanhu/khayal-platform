import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplate(
      title: 'Doctor Dashboard',
      subtitle: 'Overview for assigned patients',
      child: Column(
        children: [
          InfoTile(label: 'Assigned Patients', value: '12'),
          InfoTile(label: 'Critical Missed Doses Today', value: '2'),
          SizedBox(height: 14),
          QuickNavWrap(
            routes: {
              'Patient List': AppRoutes.doctorPatientList,
              'Open Patient History': AppRoutes.doctorPatientHistory,
              'Settings': AppRoutes.settings,
            },
          ),
        ],
      ),
    );
  }
}
