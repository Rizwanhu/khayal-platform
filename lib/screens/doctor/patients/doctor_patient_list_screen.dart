import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';

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
      title: 'Doctor Patient List',
      subtitle: 'Assigned patients from Supabase',
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Text(_error!)
              : Column(
                children:
                    _patients
                        .map(
                          (p) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(p.patientName),
                              subtitle: Text(p.subtitle),
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
                        )
                        .toList(),
              ),
    );
  }
}
