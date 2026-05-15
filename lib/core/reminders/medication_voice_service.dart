import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Urdu TTS for dose reminders (patient + caregiver). Skipped on web.
class MedicationVoiceService {
  MedicationVoiceService._();
  static final MedicationVoiceService instance = MedicationVoiceService._();

  FlutterTts? _tts;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (kIsWeb) return;
    if (_configured) return;
    final tts = FlutterTts();
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1);
    await tts.setPitch(1);
    try {
      await tts.setLanguage('ur-PK');
    } catch (_) {
      try {
        await tts.setLanguage('ur_IN');
      } catch (_) {
        try {
          await tts.setLanguage('hi-IN');
        } catch (_) {
          await tts.setLanguage('en-US');
        }
      }
    }
    _tts = tts;
    _configured = true;
  }

  /// Speaks: "دوا کا وقت ہو گیا ہے۔" and optionally the medicine name in Urdu.
  Future<void> announceUrduDoseReminder({String? medicineNameUr}) async {
    if (kIsWeb) return;
    try {
      await _ensureConfigured();
      final tts = _tts;
      if (tts == null) return;

      final b = StringBuffer('دوا کا وقت ہو گیا ہے۔');
      final extra = medicineNameUr?.trim();
      if (extra != null && extra.isNotEmpty) {
        b.write(' ');
        b.write(extra);
        b.write('۔');
      }
      await tts.speak(b.toString());
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
