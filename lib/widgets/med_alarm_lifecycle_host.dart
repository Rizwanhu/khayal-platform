import 'package:flutter/material.dart';

import '../core/backend/app_session.dart';
import '../core/reminders/medication_alarm_scheduler.dart';
import '../core/reminders/medication_notification_service.dart';

/// Keeps OS dose alarms + in-app popup active for logged-in patients (any screen).
class MedAlarmLifecycleHost extends StatefulWidget {
  const MedAlarmLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  State<MedAlarmLifecycleHost> createState() => _MedAlarmLifecycleHostState();
}

class _MedAlarmLifecycleHostState extends State<MedAlarmLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAlarms());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MedicationAlarmScheduler.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAlarms();
    }
  }

  Future<void> _syncAlarms() async {
    await MedicationNotificationService.instance.requestAndroidPermissions();
    await MedicationAlarmScheduler.instance.refreshForCurrentPatient();
    if (!mounted) return;
    if (AppSession.currentRole == AppRole.patient) {
      MedicationNotificationService.instance.consumePendingLaunchNavigation(
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
