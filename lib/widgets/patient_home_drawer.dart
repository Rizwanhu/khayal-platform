import 'package:flutter/material.dart';

import '../core/i18n/app_strings.dart';
import '../core/navigation/app_routes.dart';

/// Side menu for the patient dashboard (medicines, map, home area, doctor chat).
class PatientHomeDrawer extends StatelessWidget {
  const PatientHomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF608266)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Khayal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'KhayalRoboto',
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: Text(AppStrings.myMedicines),
              subtitle: Text(AppStrings.myMedicinesManage),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.medicationManagement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Clinics & hospitals map'),
              subtitle: const Text('Find care near your home'),
              onTap: () {
                // Capture navigator before closing drawer — drawer [context] is
                // unmounted after pop, which blocked the map screen from opening.
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pushNamed(AppRoutes.nearbyCareMap);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: const Text('Set home area'),
              subtitle: const Text('Choose where you live on the map'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.patientHomeArea);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chat with my doctor'),
              subtitle: const Text('Paid monthly — secure messaging'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.patientDoctorChat);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(AppStrings.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}
