import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Loops the device alarm tone while a dose reminder is on screen (like a call).
abstract final class DoseAlarmRingtone {
  static bool _playing = false;

  static Future<void> start() async {
    if (kIsWeb || _playing) return;
    try {
      await FlutterRingtonePlayer().playAlarm();
      _playing = true;
    } catch (e) {
      debugPrint('khayal_platform: alarm ringtone start failed: $e');
    }
  }

  static Future<void> stop() async {
    if (kIsWeb || !_playing) return;
    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('khayal_platform: alarm ringtone stop failed: $e');
    } finally {
      _playing = false;
    }
  }
}
