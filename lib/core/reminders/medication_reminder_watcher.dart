import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/app_session.dart';
import '../backend/backend_repository.dart';
import '../navigation/app_routes.dart';
import '../time/pakistan_time.dart';
import 'reminder_preferences.dart';

/// In-app dose-time alerts: while the screen is mounted, checks [MedicationRecord]
/// schedules against the device clock and opens the notification overlay + Urdu TTS.
///
/// Does **not** replace OS push notifications when the app is killed (add later with
/// `flutter_local_notifications` + exact alarms).
mixin MedicationReminderWatcherMixin<T extends StatefulWidget> on State<T> {
  Timer? _medicationReminderTimer;
  final Set<String> _firedReminderKeys = {};
  List<MedicationRecord> _reminderMeds = [];
  String? _firedDate;

  void syncMedicationReminders(List<MedicationRecord> meds) {
    _reminderMeds = List<MedicationRecord>.from(meds);
    _medicationReminderTimer?.cancel();
    _medicationReminderTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _checkMedicationReminders(),
    );
  }

  void disposeMedicationReminders() {
    _medicationReminderTimer?.cancel();
    _medicationReminderTimer = null;
    _reminderMeds = [];
  }

  void _checkMedicationReminders() {
    if (!mounted) return;
    if (!ReminderPreferences.inAppRemindersEnabled) return;

    final today = PakistanTime.now().toIso8601String().split('T').first;
    if (_firedDate != today) {
      _firedDate = today;
      _firedReminderKeys.clear();
    }

    for (final med in _reminderMeds) {
      final raws = med.scheduleRaws.isNotEmpty
          ? med.scheduleRaws
          : [if (med.firstScheduleRaw != null) med.firstScheduleRaw!];
      for (final raw in raws) {
        if (!_scheduleMatchesCurrentMinute(raw)) continue;

        final key = '$today|${med.id}|$raw';
        if (_firedReminderKeys.contains(key)) continue;
        _firedReminderKeys.add(key);

        AppSession.pendingDoseReminder = PendingDoseReminder(
          medicationId: med.id,
          nameEn: med.nameEn,
          nameUr: med.nameUr,
          timeDisplay: med.timeLabel,
          doseUr: med.doseLabel,
          scheduleRaw: raw,
          imageStoragePath: med.imageStoragePath,
        );

        HapticFeedback.heavyImpact();
        try {
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushNamed(AppRoutes.notificationOverlay);
        });
      }
    }
  }

  bool _scheduleMatchesCurrentMinute(String? raw) {
    if (raw == null || raw.isEmpty || raw == '--:--') return false;
    final parts = raw.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return false;
    final now = PakistanTime.now();
    return now.hour == h && now.minute == m;
  }
}
