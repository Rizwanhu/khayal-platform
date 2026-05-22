import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../backend/app_session.dart';
import '../backend/backend_repository.dart';
import '../i18n/app_language.dart';
import '../navigation/app_routes.dart';
import '../time/pakistan_time.dart';
import 'dose_alarm_ringtone.dart';
import 'dose_alarm_system_sound.dart';
import 'medication_voice_service.dart';
import 'reminder_preferences.dart';

/// OS-level dose alarms (lock screen / app closed) + tap opens in-app overlay.
class MedicationNotificationService {
  MedicationNotificationService._();

  static final MedicationNotificationService instance =
      MedicationNotificationService._();

  static GlobalKey<NavigatorState>? navigatorKey;

  /// Channel id — system alarm tone when app is closed / phone locked.
  static const String _channelId = 'dose_alarms_v8';
  static const int _snoozeIdBase = 900000000;
  static const int _insistentFlag = 4;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<int> _scheduledIds = {};
  String? _pendingLaunchPayload;
  bool _initialized = false;
  AndroidNotificationSound? _osAlarmSound;

  AndroidFlutterLocalNotificationsPlugin? get androidImplementation =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static int _slotNotificationId(String medicationId, String scheduleRaw) {
    return Object.hash(medicationId, scheduleRaw).abs() % 2000000000;
  }

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _loadOsAlarmSound();
      await _ensureAndroidChannel();
      final android = androidImplementation;
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.requestFullScreenIntentPermission();
    }

    _initialized = true;
    await requestAndroidPermissions();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingLaunchPayload = payload;
        final reminder = _decodePayload(payload);
        if (reminder != null) {
          unawaited(_speakThenRing(reminder));
        }
      }
    }
  }

  Future<void> _speakThenRing(PendingDoseReminder reminder) async {
    await MedicationVoiceService.instance.announceDoseReminder(
      medicineNameEn: reminder.nameEn.trim().isEmpty ? null : reminder.nameEn,
    );
    await DoseAlarmRingtone.start();
  }

  Future<void> _loadOsAlarmSound() async {
    if (_osAlarmSound != null) return;
    _osAlarmSound = await DoseAlarmSystemSound.notificationSound();
    if (kDebugMode && _osAlarmSound != null) {
      debugPrint('khayal_platform: using system alarm URI for dose notifications');
    }
  }

  AndroidNotificationChannel _androidChannel() {
    return AndroidNotificationChannel(
      _channelId,
      'Medicine alarms',
      description: 'Loud dose reminders — phone alarm tone when locked',
      importance: Importance.max,
      playSound: true,
      sound: _osAlarmSound,
      enableVibration: true,
      enableLights: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 1000, 400, 1000, 400, 1500]),
    );
  }

  Future<void> _ensureAndroidChannel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _loadOsAlarmSound();
    await androidImplementation?.createNotificationChannel(_androidChannel());
  }

  Future<void> requestAndroidPermissions({bool force = false}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final android = androidImplementation;
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();
    if (force) {
      final canExact = await android?.canScheduleExactNotifications() ?? true;
      debugPrint('khayal_platform: canScheduleExactNotifications=$canExact');
    }
  }

  Future<void> syncSchedules({
    required String patientId,
    required List<MedicationRecord> meds,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _ensureAndroidChannel();
      await cancelAllDoseReminders();

      if (!ReminderPreferences.inAppRemindersEnabled) {
        debugPrint('khayal_platform: dose alarms skipped (reminders disabled)');
        return;
      }

      var scheduledCount = 0;
      for (final med in meds) {
        final raws = med.scheduleRaws.isNotEmpty
            ? med.scheduleRaws
            : [if (med.firstScheduleRaw != null) med.firstScheduleRaw!];
        for (final raw in raws) {
          if (raw.isEmpty || raw == '--:--') continue;
          final ok = await _scheduleDailySlot(med: med, scheduleRaw: raw);
          if (ok) scheduledCount++;
        }
      }

      if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
        final pending = await androidImplementation
            ?.pendingNotificationRequests();
        debugPrint(
          'khayal_platform: scheduled $scheduledCount slot(s); '
          '${pending?.length ?? 0} pending OS notification(s)',
        );
      }
    } catch (e, st) {
      debugPrint('khayal_platform: syncSchedules failed: $e\n$st');
    }
  }

  Future<void> cancelAllDoseReminders() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await androidImplementation?.cancelAll();
    }
    for (final id in _scheduledIds.toList()) {
      await _plugin.cancel(id);
    }
    _scheduledIds.clear();
  }

  /// Shows a loud notification immediately (backup when app is open at dose time).
  Future<void> showDoseAlarmNow(PendingDoseReminder reminder) async {
    if (kIsWeb || !_initialized) return;
    if (!ReminderPreferences.inAppRemindersEnabled) return;

    final raw = reminder.scheduleRaw ?? '';
    final id = raw.isEmpty
        ? reminder.medicationId.hashCode.abs() % 2000000000
        : _slotNotificationId(reminder.medicationId, raw);

    await _plugin.show(
      id,
      _notificationTitle(),
      _notificationBody(
        nameEn: reminder.nameEn,
        nameUr: reminder.nameUr,
        doseUr: reminder.doseUr,
      ),
      _notificationDetails(),
      payload: _encodePayload(reminder),
    );
  }

  Future<void> scheduleSnooze(PendingDoseReminder reminder) async {
    if (kIsWeb || !_initialized) return;
    if (!ReminderPreferences.inAppRemindersEnabled) return;

    final id = _snoozeIdBase +
        Object.hash(reminder.medicationId, reminder.scheduleRaw).abs() %
            99999;
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15));
    final payload = _encodePayload(reminder);

    await _zonedScheduleWithFallback(
      id: id,
      title: _notificationTitle(),
      body: _notificationBody(
        nameEn: reminder.nameEn,
        nameUr: reminder.nameUr,
        doseUr: reminder.doseUr,
      ),
      when: when,
      payload: payload,
      matchDaily: false,
    );
    _scheduledIds.add(id);
  }

  void consumePendingLaunchNavigation(BuildContext context) {
    final payload = _pendingLaunchPayload;
    if (payload == null || payload.isEmpty) return;
    _pendingLaunchPayload = null;
    final reminder = _decodePayload(payload);
    if (reminder != null) {
      unawaited(_speakThenRing(reminder));
    } else {
      DoseAlarmRingtone.start();
    }
    _openOverlayFromPayload(context, payload);
  }

  tz.TZDateTime _nextDailyFireTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<bool> _scheduleDailySlot({
    required MedicationRecord med,
    required String scheduleRaw,
  }) async {
    final min = PakistanTime.parseScheduleToMinutes(scheduleRaw);
    if (min == null) {
      debugPrint(
        'khayal_platform: skip invalid schedule "$scheduleRaw" for ${med.id}',
      );
      return false;
    }
    final h = min ~/ 60;
    final m = min % 60;

    final id = _slotNotificationId(med.id, scheduleRaw);
    final first = _nextDailyFireTime(hour: h, minute: m);
    final payload = _encodePayload(
      PendingDoseReminder(
        medicationId: med.id,
        nameEn: med.nameEn,
        nameUr: med.nameUr,
        timeDisplay: med.timeLabel,
        doseUr: med.doseLabel,
        scheduleRaw: scheduleRaw,
        imageStoragePath: med.imageStoragePath,
      ),
    );

    final ok = await _zonedScheduleWithFallback(
      id: id,
      title: _notificationTitle(),
      body: _notificationBody(
        nameEn: med.nameEn,
        nameUr: med.nameUr,
        doseUr: med.doseLabel,
      ),
      when: first,
      payload: payload,
      matchDaily: true,
    );
    if (ok) _scheduledIds.add(id);
    return ok;
  }

  Future<bool> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    required bool matchDaily,
  }) async {
    final details = _notificationDetails();
    final components =
        matchDaily ? DateTimeComponents.time : null;

    for (final mode in [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          matchDateTimeComponents: components,
          payload: payload,
        );
        if (kDebugMode) {
          debugPrint(
            'khayal_platform: scheduled id=$id at $when mode=$mode',
          );
        }
        return true;
      } catch (e) {
        debugPrint('khayal_platform: schedule id=$id mode=$mode failed: $e');
      }
    }
    return false;
  }

  NotificationDetails _notificationDetails() {
    final android = AndroidNotificationDetails(
      _channelId,
      'Medicine alarms',
      channelDescription: 'Loud dose reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: _osAlarmSound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'دوا کا وقت — Medicine time',
      ongoing: false,
      autoCancel: true,
      onlyAlertOnce: false,
      channelShowBadge: true,
      additionalFlags: Int32List.fromList([_insistentFlag]),
      vibrationPattern: Int64List.fromList([0, 1000, 400, 1000, 400, 1500]),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  String _notificationTitle() {
    return AppLanguageState.pick(
      en: 'Medicine time',
      ur: 'دوا کا وقت ہو گیا',
    );
  }

  String _notificationBody({
    required String nameEn,
    required String nameUr,
    required String doseUr,
  }) {
    final name = nameEn.trim().isNotEmpty ? nameEn.trim() : nameUr.trim();
    final dose = doseUr.trim();
    if (dose.isEmpty) return name;
    return '$name — $dose';
  }

  String _encodePayload(PendingDoseReminder reminder) {
    return jsonEncode({
      'medicationId': reminder.medicationId,
      'nameEn': reminder.nameEn,
      'nameUr': reminder.nameUr,
      'timeDisplay': reminder.timeDisplay,
      'doseUr': reminder.doseUr,
      'scheduleRaw': reminder.scheduleRaw,
      'imageStoragePath': reminder.imageStoragePath,
    });
  }

  PendingDoseReminder? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return PendingDoseReminder(
        medicationId: map['medicationId']?.toString() ?? '',
        nameEn: map['nameEn']?.toString() ?? '',
        nameUr: map['nameUr']?.toString() ?? '',
        timeDisplay: map['timeDisplay']?.toString() ?? '',
        doseUr: map['doseUr']?.toString() ?? '',
        scheduleRaw: map['scheduleRaw']?.toString(),
        imageStoragePath: map['imageStoragePath']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final reminder = _decodePayload(payload);
    if (reminder == null) return;
    AppSession.pendingDoseReminder = reminder;
    unawaited(_speakThenRing(reminder));

    final nav = navigatorKey?.currentState;
    if (nav != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nav.mounted) {
          nav.pushNamed(AppRoutes.notificationOverlay);
        }
      });
    } else {
      _pendingLaunchPayload = payload;
    }
  }

  void _openOverlayFromPayload(BuildContext context, String payload) {
    final reminder = _decodePayload(payload);
    if (reminder == null) return;
    AppSession.pendingDoseReminder = reminder;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.notificationOverlay);
    });
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  // Tap handled when app resumes via onDidReceiveNotificationResponse / launch details.
}
