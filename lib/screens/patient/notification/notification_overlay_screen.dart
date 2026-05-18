import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/reminders/dose_alarm_ringtone.dart';
import '../../../core/reminders/medication_notification_service.dart';
import '../../../core/reminders/medication_voice_service.dart';
import '../widgets/dose_reminder_panel.dart';

/// Modal-style reminder over dimmed scrim — same card as dose confirmation.
class NotificationOverlayScreen extends StatefulWidget {
  const NotificationOverlayScreen({super.key});

  @override
  State<NotificationOverlayScreen> createState() =>
      _NotificationOverlayScreenState();
}

class _NotificationOverlayScreenState extends State<NotificationOverlayScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scrimController;
  late final Animation<double> _scrimOpacity;

  late final AnimationController _cardController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _scrimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scrimOpacity = CurvedAnimation(
      parent: _scrimController,
      curve: Curves.easeOut,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _scrimController.forward();
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    DoseAlarmRingtone.stop();
    MedicationVoiceService.instance.stop();
    _scrimController.dispose();
    _cardController.dispose();
    AppSession.clearPendingDoseReminder();
    super.dispose();
  }

  Future<void> _close() async {
    await DoseAlarmRingtone.stop();
    await MedicationVoiceService.instance.stop();
    await _cardController.reverse();
    if (!mounted) return;
    await _scrimController.reverse();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onTookIt() async {
    HapticFeedback.mediumImpact();
    if (AppSession.currentRole == AppRole.caregiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test alert preview — the patient confirms doses on their device.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _close();
      return;
    }

    final patientId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    final pending = AppSession.pendingDoseReminder;
    if (patientId != null &&
        patientId.isNotEmpty &&
        pending != null &&
        pending.medicationId.isNotEmpty) {
      try {
        await Backend.repo.confirmDose(
          patientId: patientId,
          medicationId: pending.medicationId,
          status: 'taken',
          scheduleRaw: pending.scheduleRaw,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.doseTakenSuccess);
  }

  Future<void> _onSnooze() async {
    HapticFeedback.selectionClick();
    final pending = AppSession.pendingDoseReminder;
    if (pending != null) {
      await MedicationNotificationService.instance.scheduleSnooze(pending);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguageState.pick(
            en: 'Reminder in 15 minutes.',
            ur: '۱۵ منٹ بعد یاد دہانی۔',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_scrimController, _cardController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _close();
                },
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.42 * _scrimOpacity.value,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: DoseReminderPanel(
                        headline: AppLanguageState.pick(
                          en: 'Time to take your medicine!',
                          ur: 'دوا کا وقت ہو گیا!',
                        ),
                        nameEn: AppSession.pendingDoseReminder?.nameEn ??
                            'Paracetamol',
                        nameUr: AppSession.pendingDoseReminder?.nameUr ??
                            'پیراسیٹامول',
                        time: AppSession.pendingDoseReminder?.timeDisplay ??
                            '08:00',
                        doseUr: AppSession.pendingDoseReminder?.doseUr ??
                            '1 گولی',
                        imageStoragePath:
                            AppSession.pendingDoseReminder?.imageStoragePath,
                        onTookIt: () => _onTookIt(),
                        onSnooze: () => _onSnooze(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
