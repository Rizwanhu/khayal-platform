import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/medication/dose_missed_sync.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/ui/doctor_shell_colors.dart';
import '../../../core/ui/doctor_ui_tokens.dart';
import '../../../core/ui/doctor_ui_widgets.dart';
import '../../../widgets/doctor_patient_tile.dart';
import '../../../widgets/doctor_shell_scaffold.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _loading = true;
  String? _error;
  int _patientCount = 0;
  int _missedToday = 0;
  List<DoctorPatientSummary> _patients = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doctorId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (doctorId == null || doctorId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing doctor session. Sign in first.';
      });
      return;
    }
    try {
      final patientList = await Backend.repo.getDoctorPatients(doctorId);
      for (final p in patientList) {
        await DoseMissedSync.syncForPatient(p.patientId);
      }
      final missed = await Backend.repo.countMissedDosesTodayForDoctor(
        doctorId,
      );
      if (!mounted) return;
      setState(() {
        _patients = patientList;
        _patientCount = patientList.length;
        _missedToday = missed;
        _loading = false;
        if (patientList.isNotEmpty &&
            (AppSession.selectedPatientId == null ||
                !patientList.any(
                  (p) => p.patientId == AppSession.selectedPatientId,
                ))) {
          AppSession.selectedPatientId = patientList.first.patientId;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load dashboard: $e';
      });
    }
  }

  void _openChat(String patientId) {
    AppSession.selectedPatientId = patientId;
    Navigator.pushNamed(
      context,
      AppRoutes.doctorPatientChat,
      arguments: patientId,
    );
  }

  void _openHistory(String patientId) {
    AppSession.selectedPatientId = patientId;
    Navigator.pushNamed(context, AppRoutes.doctorPatientHistory);
  }

  @override
  Widget build(BuildContext context) {
    return DoctorShellScaffold(
      title: 'Doctor dashboard',
      subtitle: 'Assigned patients & alerts',
      drawerRoute: AppRoutes.doctorDashboard,
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
      return DoctorUi.errorBox(_error!, onRetry: () {
        setState(() {
          _loading = true;
          _error = null;
        });
        _load();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DoctorUi.statCard(
              icon: Icons.people_outline_rounded,
              label: 'Assigned patients',
              value: '$_patientCount',
              accent: DoctorShellColors.statPatients,
            ),
            const SizedBox(width: DoctorUiTokens.gapItem),
            DoctorUi.statCard(
              icon: Icons.warning_amber_rounded,
              label: 'Missed doses today',
              value: '$_missedToday',
              accent: DoctorShellColors.statMissed,
            ),
          ],
        ),
        const SizedBox(height: DoctorUiTokens.gapSection),
        if (_patientCount == 0) ...[
          DoctorUi.emptyState(
            icon: Icons.person_add_alt_1_outlined,
            title: 'No patients linked yet',
            message:
                'Ask your patient to tap the key icon on their home screen and share their phone number and 6-digit code.',
          ),
          DoctorUi.primaryButton(
            label: 'Link a patient with code',
            icon: Icons.link_rounded,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.doctorPatientSetup)
                  .then((_) => _load());
            },
          ),
        ] else ...[
          DoctorUi.sectionLabel('Your patients'),
          ..._patients.map(
            (p) => DoctorPatientTile(
              patient: p,
              selected: p.patientId == AppSession.selectedPatientId,
              onMessage: () => _openChat(p.patientId),
              onHistory: () => _openHistory(p.patientId),
            ),
          ),
          const SizedBox(height: 8),
          DoctorUi.primaryButton(
            label: 'Link another patient',
            icon: Icons.person_add_outlined,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.doctorPatientSetup)
                  .then((_) => _load());
            },
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Use ☰ menu for full patient list, dose history, and settings.',
          textAlign: TextAlign.center,
          style: DoctorUiTokens.bodyStyle().copyWith(
            fontSize: DoctorUiTokens.caption,
          ),
        ),
      ],
    );
  }
}
