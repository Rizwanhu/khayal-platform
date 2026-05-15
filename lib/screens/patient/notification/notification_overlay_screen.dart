import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/navigation/app_routes.dart';
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
    _scrimController.dispose();
    _cardController.dispose();
    AppSession.clearPendingDoseReminder();
    super.dispose();
  }

  Future<void> _close() async {
    await _cardController.reverse();
    if (!mounted) return;
    await _scrimController.reverse();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onTookIt() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacementNamed(context, AppRoutes.doseTakenSuccess);
  }

  void _onSnooze() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder set for 15 minutes from now.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _close();
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
                        nameEn: AppSession.pendingDoseReminder?.nameEn ??
                            'Paracetamol',
                        nameUr: AppSession.pendingDoseReminder?.nameUr ??
                            'پیراسیٹامول',
                        time: AppSession.pendingDoseReminder?.timeDisplay ??
                            '08:00',
                        doseUr: AppSession.pendingDoseReminder?.doseUr ??
                            '1 گولی',
                        onTookIt: _onTookIt,
                        onSnooze: _onSnooze,
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
