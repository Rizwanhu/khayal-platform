import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS for dose reminders: Urdu phrase then English medicine name.
class MedicationVoiceService {
  MedicationVoiceService._();
  static final MedicationVoiceService instance = MedicationVoiceService._();

  FlutterTts? _tts;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (kIsWeb) return;
    if (_configured) return;
    final tts = FlutterTts();
    await tts.setSpeechRate(0.48);
    await tts.setVolume(1.0);
    await tts.setPitch(1.05);
    await tts.awaitSpeakCompletion(true);
    _tts = tts;
    _configured = true;
  }

  /// Speaks "دوا کا وقت ہو گیا ہے" then the English medicine name.
  Future<void> announceDoseReminder({String? medicineNameEn}) async {
    if (kIsWeb) return;
    try {
      await _ensureConfigured();
      final tts = _tts;
      if (tts == null) return;

      await tts.stop();

      try {
        await tts.setLanguage('ur-PK');
      } catch (_) {
        try {
          await tts.setLanguage('ur_IN');
        } catch (_) {}
      }

      await tts.speak('دوا کا وقت ہو گیا ہے');

      final name = medicineNameEn?.trim();
      if (name != null && name.isNotEmpty) {
        try {
          await tts.setLanguage('en-US');
        } catch (_) {}
        await tts.speak(name);
      }
    } catch (e) {
      debugPrint('MedicationVoiceService: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
