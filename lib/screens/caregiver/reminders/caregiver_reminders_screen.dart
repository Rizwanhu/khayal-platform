import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/medication/med_patient_context.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/reminders/reminder_preferences.dart';
import '../../../core/time/medication_dose_status.dart';
import '../../../core/time/pakistan_time.dart';
import '../caregiver_colors.dart';

/// Caregiver hub for in-app dose reminders and alert testing.
class CaregiverRemindersScreen extends StatefulWidget {
  const CaregiverRemindersScreen({super.key});

  @override
  State<CaregiverRemindersScreen> createState() =>
      _CaregiverRemindersScreenState();
}

class _CaregiverRemindersScreenState extends State<CaregiverRemindersScreen> {
  bool _loading = true;
  String? _error;
  String? _patientName;
  List<_DoseRow> _upcoming = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final patientId = await MedPatientContext.resolvePatientId();
      if (patientId == null) {
        setState(() {
          _loading = false;
          _error = 'No linked patient. Link a patient from Settings first.';
        });
        return;
      }

      final profile = await Backend.repo.getPatientProfile(patientId);
      final meds = await Backend.repo.getMedicationsForPatient(patientId);
      final rows = <_DoseRow>[];

      for (final med in meds) {
        final raws = med.scheduleRaws.isNotEmpty
            ? med.scheduleRaws
            : [med.firstScheduleRaw];
        for (final raw in raws) {
          if (raw == null || raw.isEmpty) continue;
          final status = MedicationDoseStatusLogic.fromScheduleRaw(raw);
          if (status == MedicationDoseStatus.missed) continue;
          rows.add(
            _DoseRow(
              medName: med.nameEn,
              timeLabel: _formatSchedule(raw),
              status: status,
              scheduleRaw: raw,
              medicationId: med.id,
              nameUr: med.nameUr,
              doseLabel: med.doseLabel,
            ),
          );
        }
      }

      rows.sort((a, b) {
        final am = PakistanTime.parseScheduleToMinutes(a.scheduleRaw) ?? 0;
        final bm = PakistanTime.parseScheduleToMinutes(b.scheduleRaw) ?? 0;
        return am.compareTo(bm);
      });

      if (!mounted) return;
      setState(() {
        _patientName = profile?.fullName ?? 'Patient';
        _upcoming = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  String _formatSchedule(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    final suffix = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final min = tod.minute.toString().padLeft(2, '0');
    return '$hour:$min $suffix';
  }

  void _testAlert() {
    if (_upcoming.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add medications with times first.')),
      );
      return;
    }
    final row = _upcoming.firstWhere(
      (r) =>
          r.status == MedicationDoseStatus.dueSoon ||
          r.status == MedicationDoseStatus.upcoming,
      orElse: () => _upcoming.first,
    );
    HapticFeedback.mediumImpact();
    AppSession.pendingDoseReminder = PendingDoseReminder(
      medicationId: row.medicationId,
      nameEn: row.medName,
      nameUr: row.nameUr,
      timeDisplay: row.timeLabel,
      doseUr: row.doseLabel,
      scheduleRaw: row.scheduleRaw,
    );
    Navigator.pushNamed(context, AppRoutes.notificationOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaregiverColors.canvas,
      appBar: AppBar(
        backgroundColor: CaregiverColors.header,
        foregroundColor: Colors.white,
        title: const Text('Reminders & alerts'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                children: [
                  if (_patientName != null)
                    Text(
                      'Reminders for $_patientName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In-app dose reminders'),
                    subtitle: const Text(
                      'Alert sound and card while Khayal is open (patient and caregiver).',
                    ),
                    value: ReminderPreferences.inAppRemindersEnabled,
                    onChanged: (v) async {
                      await ReminderPreferences.setEnabled(v);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _testAlert,
                      style: FilledButton.styleFrom(
                        backgroundColor: CaregiverColors.headerForm,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Test alert now'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Alert history'),
                    subtitle: const Text('Past missed and reminder events'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.alertHistory);
                    },
                  ),
                  const Divider(height: 32),
                  Text(
                    "Today's dose times",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CaregiverColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_upcoming.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No upcoming doses today. Add medicines with schedule times.',
                        style: TextStyle(color: CaregiverColors.textMuted),
                      ),
                    )
                  else
                    ..._upcoming.map((row) {
                      final label = switch (row.status) {
                        MedicationDoseStatus.dueSoon => 'Due soon',
                        MedicationDoseStatus.upcoming => 'Upcoming',
                        MedicationDoseStatus.missed => 'Missed',
                      };
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(row.medName),
                          subtitle: Text('$label · ${row.timeLabel}'),
                          trailing: Icon(
                            row.status == MedicationDoseStatus.dueSoon
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_rounded,
                            color: row.status == MedicationDoseStatus.dueSoon
                                ? Colors.orange.shade800
                                : CaregiverColors.textMuted,
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text(
                    'Push notifications when the app is closed will be added in a future update.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CaregiverColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DoseRow {
  const _DoseRow({
    required this.medName,
    required this.timeLabel,
    required this.status,
    required this.scheduleRaw,
    required this.medicationId,
    required this.nameUr,
    required this.doseLabel,
  });

  final String medName;
  final String timeLabel;
  final MedicationDoseStatus status;
  final String scheduleRaw;
  final String medicationId;
  final String nameUr;
  final String doseLabel;
}
