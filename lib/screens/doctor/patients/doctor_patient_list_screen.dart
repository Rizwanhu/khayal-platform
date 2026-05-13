import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

class DoctorPatientListScreen extends StatelessWidget {
  const DoctorPatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'Doctor Patient List',
      subtitle: 'Assigned patients (frontend sample)',
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Muhammad Ali'),
              subtitle: const Text('Age 68 · Last dose: 08:00 AM'),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.doctorPatientHistory,
                  ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Fatima Bibi'),
              subtitle: const Text('Age 72 · Last dose: 07:30 AM'),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.doctorPatientHistory,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
