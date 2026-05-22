import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_session.dart';
import '../backend/backend.dart';
import '../backend/backend_repository.dart';
import '../navigation/app_routes.dart';
import '../time/pakistan_time.dart';
import 'dose_alarm_ringtone.dart';
import 'medication_notification_service.dart';
import 'medication_voice_service.dart';
import 'reminder_preferences.dart';

/// In-app dose popup + reschedules OS alarms whenever the patient session is active.
class MedicationAlarmScheduler {
  MedicationAlarmScheduler._();

  static final MedicationAlarmScheduler instance = MedicationAlarmScheduler._();

  Timer? _timer;
  final Set<String> _firedKeys = {};
  String? _firedDate;
  List<MedicationRecord> _meds = [];
  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> refreshForCurrentPatient() async {
    if (!ReminderPreferences.inAppRemindersEnabled) {
      stop();
      return;
    }

    final role = AppSession.currentRole;
    final userId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (role != AppRole.patient || userId == null || userId.isEmpty) {
      stop();
      return;
    }

    try {
      final meds = await Backend.repo.getMedicationsForPatient(userId);
      _meds = meds;
      await MedicationNotificationService.instance.syncSchedules(
        patientId: userId,
        meds: meds,
      );
      _ensureTimer();
    } catch (_) {
      _meds = [];
    }
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _meds = [];
  }

  Future<void> _presentDoseReminder(
    PendingDoseReminder reminder,
    MedicationRecord med,
  ) async {
    await MedicationVoiceService.instance.announceDoseReminder(
      medicineNameEn: med.nameEn.trim().isEmpty ? null : med.nameEn,
    );
    await DoseAlarmRingtone.start();
    await MedicationNotificationService.instance.showDoseAlarmNow(reminder);

    final nav = _navigatorKey?.currentState;
    if (nav != null && nav.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nav.mounted) {
          nav.pushNamed(AppRoutes.notificationOverlay);
        }
      });
    }
  }

  void _tick() {
    if (!ReminderPreferences.inAppRemindersEnabled) return;

    final today = PakistanTime.now().toIso8601String().split('T').first;
    if (_firedDate != today) {
      _firedDate = today;
      _firedKeys.clear();
    }

    for (final med in _meds) {
      final raws = med.scheduleRaws.isNotEmpty
          ? med.scheduleRaws
          : [if (med.firstScheduleRaw != null) med.firstScheduleRaw!];
      for (final raw in raws) {
        if (!_matchesNow(raw)) continue;
        final key = '$today|${med.id}|$raw';
        if (_firedKeys.contains(key)) continue;
        _firedKeys.add(key);

        final reminder = PendingDoseReminder(
          medicationId: med.id,
          nameEn: med.nameEn,
          nameUr: med.nameUr,
          timeDisplay: med.timeLabel,
          doseUr: med.doseLabel,
          scheduleRaw: raw,
          imageStoragePath: med.imageStoragePath,
        );
        AppSession.pendingDoseReminder = reminder;

        HapticFeedback.heavyImpact();
        unawaited(_presentDoseReminder(reminder, med));
      }
    }
  }

  bool _matchesNow(String? raw) {
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
