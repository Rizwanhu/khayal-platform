import 'package:flutter/material.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/medication/dose_missed_sync.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/doctor_shell_colors.dart';
import '../../../core/ui/doctor_ui_tokens.dart';
import '../../../core/ui/doctor_ui_widgets.dart';
import '../../../widgets/doctor_shell_scaffold.dart';

class DoctorPatientHistoryScreen extends StatefulWidget {
  const DoctorPatientHistoryScreen({super.key});

  @override
  State<DoctorPatientHistoryScreen> createState() =>
      _DoctorPatientHistoryScreenState();
}

class _DoctorPatientHistoryScreenState
    extends State<DoctorPatientHistoryScreen> {
  bool _loading = true;
  String? _error;
  String _patientName = '';
  List<PatientHistoryRecord> _rows = const [];
  List<DoctorPatientSummary> _allPatients = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doctorId = AppSession.currentUserId;
    if (doctorId == null || doctorId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sign in as doctor first.';
      });
      return;
    }

    try {
      final patients = await Backend.repo.getDoctorPatients(doctorId);
      var patientId = AppSession.selectedPatientId;
      if (patientId == null && patients.isNotEmpty) {
        patientId = patients.first.patientId;
        AppSession.selectedPatientId = patientId;
      }
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _allPatients = patients;
          _loading = false;
          _error = 'No patient selected. Link a patient from the menu.';
        });
        return;
      }

      await DoseMissedSync.syncForPatient(patientId);
      final profile = await Backend.repo.getPatientProfile(patientId);
      final history = await Backend.repo.getPatientHistory(patientId);
      setState(() {
        _allPatients = patients;
        _patientName = profile?.fullName ?? 'Unknown patient';
        _rows = history;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load patient history: $e';
      });
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Taken' => AppTheme.takenGreen,
      'Missed' => AppTheme.missedRed,
      _ => AppTheme.upcomingAmber,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DoctorShellScaffold(
      title: 'Dose history',
      subtitle: _patientName.isNotEmpty
          ? 'Adherence · $_patientName'
          : 'Patient adherence',
      onRefresh: _load,
      body: Padding(
        padding: const EdgeInsets.all(DoctorUiTokens.paddingScreen),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return DoctorUi.loading();
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DoctorUi.errorBox(_error!),
          if (_allPatients.isEmpty) ...[
            const SizedBox(height: 16),
            DoctorUi.primaryButton(
              label: 'Link a patient',
              icon: Icons.link_rounded,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.doctorPatientSetup,
                ).then((_) => _load());
              },
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_allPatients.length > 1) ...[
          Material(
            color: DoctorShellColors.card,
            borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: AppSession.selectedPatientId,
                decoration: const InputDecoration(
                  labelText: 'Patient',
                  border: InputBorder.none,
                ),
                items: [
                  for (final p in _allPatients)
                    DropdownMenuItem(
                      value: p.patientId,
                      child: Text(p.patientName),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  AppSession.selectedPatientId = id;
                  setState(() => _loading = true);
                  _load();
                },
              ),
            ),
          ),
          const SizedBox(height: DoctorUiTokens.gapItem),
        ],
        DoctorUi.primaryButton(
          label: 'Message $_patientName',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () {
            final id = AppSession.selectedPatientId;
            if (id == null) return;
            Navigator.pushNamed(
              context,
              AppRoutes.doctorPatientChat,
              arguments: id,
            );
          },
        ),
        const SizedBox(height: DoctorUiTokens.gapSection),
        DoctorUi.sectionLabel('Recent doses'),
        if (_rows.isEmpty)
          DoctorUi.emptyState(
            icon: Icons.medication_outlined,
            title: 'No history yet',
            message: 'Dose confirmations will appear here once recorded.',
          )
        else
          ..._rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: DoctorUiTokens.gapItem),
              child: Material(
                color: DoctorShellColors.card,
                borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  title: Text(
                    r.dayLabel,
                    style: DoctorUiTokens.labelStyle(
                      size: DoctorUiTokens.body,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(r.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      r.status,
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                        color: _statusColor(r.status),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
