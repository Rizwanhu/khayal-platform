import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_repository.dart';
import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

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
        _error = 'Missing doctor session. Login with phone OTP first.';
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
    return ScreenTemplate(
      title: 'My patients',
      subtitle: 'Patients linked to your account',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Text(_error!)
          : _patients.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('No patients linked yet.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.doctorPatientSetup,
                    );
                    if (mounted) _load();
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Add patient with code'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.doctorPatientSetup,
                    );
                    if (mounted) _load();
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add another patient'),
                ),
                const SizedBox(height: 12),
                ..._patients.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(p.patientName),
                      subtitle: const Text('View dose history'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppSession.selectedPatientId = p.patientId;
                        Navigator.pushNamed(
                          context,
                          AppRoutes.doctorPatientHistory,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
