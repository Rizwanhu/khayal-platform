import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/ui/doctor_ui_tokens.dart';
import '../../../core/ui/doctor_ui_widgets.dart';
import '../../../widgets/doctor_patient_tile.dart';
import '../../../widgets/doctor_shell_scaffold.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() =>
      _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  bool _loading = true;
  String? _error;
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
      final rows = await Backend.repo.getDoctorPatients(doctorId);
      setState(() {
        _patients = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load patients: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorShellScaffold(
      title: 'All patients',
      subtitle: 'Linked to your account',
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
    if (_patients.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DoctorUi.emptyState(
            icon: Icons.people_outline,
            title: 'No patients yet',
            message: 'Link a patient using their phone and 6-digit code.',
          ),
          DoctorUi.primaryButton(
            label: 'Add patient with code',
            icon: Icons.link_rounded,
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.doctorPatientSetup,
              );
              if (mounted) _load();
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorUi.primaryButton(
          label: 'Add another patient',
          icon: Icons.person_add_outlined,
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.doctorPatientSetup,
            );
            if (mounted) _load();
          },
        ),
        const SizedBox(height: DoctorUiTokens.gapSection),
        ..._patients.map(
          (p) => DoctorPatientTile(
            patient: p,
            selected: p.patientId == AppSession.selectedPatientId,
            onMessage: () {
              AppSession.selectedPatientId = p.patientId;
              Navigator.pushNamed(
                context,
                AppRoutes.doctorPatientChat,
                arguments: p.patientId,
              );
            },
            onHistory: () {
              AppSession.selectedPatientId = p.patientId;
              Navigator.pushNamed(context, AppRoutes.doctorPatientHistory);
            },
          ),
        ),
      ],
    );
  }
}
