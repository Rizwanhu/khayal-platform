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
import 'reminder_preferences.dart';

/// OS-level dose alarms (lock screen / app closed) + tap opens in-app overlay.
class MedicationNotificationService {
  MedicationNotificationService._();

  static final MedicationNotificationService instance =
      MedicationNotificationService._();

  static GlobalKey<NavigatorState>? navigatorKey;

  static const String _channelId = 'dose_reminders';
  static const int _snoozeIdBase = 900000000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<int> _scheduledIds = {};
  String? _pendingLaunchPayload;
  bool _initialized = false;

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
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Medicine reminders',
          description: 'Alarm when it is time to take your medicine',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    _initialized = true;

    await requestAndroidPermissions();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingLaunchPayload = payload;
      }
    }
  }

  Future<void> requestAndroidPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// Call from patient home after login / load meds.
  Future<void> syncSchedules({
    required String patientId,
    required List<MedicationRecord> meds,
  }) async {
    if (kIsWeb || !_initialized) return;

    await cancelAllDoseReminders();

    if (!ReminderPreferences.inAppRemindersEnabled) return;

    for (final med in meds) {
      final raws = med.scheduleRaws.isNotEmpty
          ? med.scheduleRaws
          : [if (med.firstScheduleRaw != null) med.firstScheduleRaw!];
      for (final raw in raws) {
        if (raw.isEmpty || raw == '--:--') continue;
        await _scheduleDailySlot(med: med, scheduleRaw: raw);
      }
    }
  }

  Future<void> cancelAllDoseReminders() async {
    if (kIsWeb) return;
    for (final id in _scheduledIds.toList()) {
      await _plugin.cancel(id);
    }
    _scheduledIds.clear();
  }

  Future<void> scheduleSnooze(PendingDoseReminder reminder) async {
    if (kIsWeb || !_initialized) return;
    if (!ReminderPreferences.inAppRemindersEnabled) return;

    final id = _snoozeIdBase +
        Object.hash(reminder.medicationId, reminder.scheduleRaw).abs() %
            99999;
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15));
    final payload = _encodePayload(reminder);

    await _plugin.zonedSchedule(
      id,
      _notificationTitle(),
      _notificationBody(
        nameEn: reminder.nameEn,
        nameUr: reminder.nameUr,
        doseUr: reminder.doseUr,
      ),
      when,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    _scheduledIds.add(id);
  }

  /// Opens overlay if app was launched from a dose notification.
  void consumePendingLaunchNavigation(BuildContext context) {
    final payload = _pendingLaunchPayload;
    if (payload == null || payload.isEmpty) return;
    _pendingLaunchPayload = null;
    _openOverlayFromPayload(context, payload);
  }

  Future<void> _scheduleDailySlot({
    required MedicationRecord med,
    required String scheduleRaw,
  }) async {
    final parts = scheduleRaw.split(':');
    if (parts.length < 2) return;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return;

    final id = _slotNotificationId(med.id, scheduleRaw);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (!first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
    }

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

    await _plugin.zonedSchedule(
      id,
      _notificationTitle(),
      _notificationBody(
        nameEn: med.nameEn,
        nameUr: med.nameUr,
        doseUr: med.doseLabel,
      ),
      first,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
    _scheduledIds.add(id);
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      'Medicine reminders',
      channelDescription: 'Alarm when it is time to take your medicine',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      ticker: 'Medicine time',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return const NotificationDetails(android: android, iOS: ios);
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
    final name = nameUr.trim().isNotEmpty ? nameUr.trim() : nameEn;
    final dose = doseUr.trim();
    if (dose.isEmpty) return name;
    return AppLanguageState.pick(
      en: '$name — $dose',
      ur: '$name — $dose',
    );
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
