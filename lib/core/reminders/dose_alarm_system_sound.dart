import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Resolves the phone's default alarm tone URI for OS notifications (app closed / locked).
abstract final class DoseAlarmSystemSound {
  static const _channel = MethodChannel('khayal_platform/alarm_sound');

  static String? _cachedUri;

  static Future<String?> alarmUri() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    if (_cachedUri != null) return _cachedUri;
    try {
      _cachedUri = await _channel.invokeMethod<String>('getAlarmUri');
    } catch (e) {
      debugPrint('khayal_platform: getAlarmUri failed: $e');
    }
    return _cachedUri;
  }

  static Future<AndroidNotificationSound?> notificationSound() async {
    final uri = await alarmUri();
    if (uri == null || uri.isEmpty) return null;
    return UriAndroidNotificationSound(uri);
  }
}
