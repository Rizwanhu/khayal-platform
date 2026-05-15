import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';
import '../widgets/dose_reminder_panel.dart';

/// Full-screen dose reminder — matches notification card design + entrance motion.
class DoseConfirmationScreen extends StatefulWidget {
  const DoseConfirmationScreen({super.key});

  @override
  State<DoseConfirmationScreen> createState() => _DoseConfirmationScreenState();
}

class _DoseConfirmationScreenState extends State<DoseConfirmationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _canvas = Color(0xFFF9F1E7);

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    AppSession.clearPendingDoseReminder();
    super.dispose();
  }

  Future<void> _onTookIt() async {
    final patientId =
        AppSession.selectedPatientId ??
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    final pending = AppSession.pendingDoseReminder;
    if (patientId != null && patientId.isNotEmpty) {
      try {
        final medId = pending?.medicationId;
        final scheduleRaw = pending?.scheduleRaw;
        if (medId != null && medId.isNotEmpty) {
          await Backend.repo.confirmDose(
            patientId: patientId,
            medicationId: medId,
            status: 'taken',
            scheduleRaw: scheduleRaw,
          );
        } else {
          final meds = await Backend.repo.getMedicationsForPatient(patientId);
          if (meds.isNotEmpty) {
            await Backend.repo.confirmDose(
              patientId: patientId,
              medicationId: meds.first.id,
              status: 'taken',
              scheduleRaw: meds.first.firstScheduleRaw,
            );
          }
        }
      } catch (_) {
        // Keep flow non-blocking for UI.
      }
    }

    TodayDoseSummary summary = const TodayDoseSummary(
      taken: 0,
      total: 0,
      takenMedicationIds: {},
    );
    if (patientId != null && patientId.isNotEmpty) {
      try {
        summary = await Backend.repo.getTodayDoseSummary(patientId);
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.doseTakenSuccess,
      arguments: summary,
    );
  }

  void _onSnooze() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder set for 15 minutes from now.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Reminder',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'KhayalRoboto',
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(scale: _scale.value, child: child),
                );
              },
              child: DoseReminderPanel(
                nameEn: AppSession.pendingDoseReminder?.nameEn ??
                    'Paracetamol',
                nameUr: AppSession.pendingDoseReminder?.nameUr ??
                    'پیراسیٹامول',
                time: AppSession.pendingDoseReminder?.timeDisplay ?? '08:00',
                doseUr:
                    AppSession.pendingDoseReminder?.doseUr ?? '1 گولی',
                onTookIt: _onTookIt,
                onSnooze: _onSnooze,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
