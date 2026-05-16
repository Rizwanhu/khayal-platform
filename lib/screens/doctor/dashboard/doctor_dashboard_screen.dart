import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'Doctor Dashboard',
      subtitle: 'Overview for assigned patients',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('Retry'),
                ),
              ],
            )
          : Column(
              children: [
                InfoTile(
                  label: 'Assigned Patients',
                  value: '$_patientCount',
                ),
                InfoTile(
                  label: 'Critical Missed Doses Today',
                  value: '$_missedToday',
                ),
                const SizedBox(height: 14),
                if (_patients.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your patients',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._patients.map(
                    (p) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person, size: 20),
                        ),
                        title: Text(p.patientName),
                        subtitle: const Text('Tap history · chat icon to message'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Chat',
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {
                                AppSession.selectedPatientId = p.patientId;
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.doctorPatientChat,
                                  arguments: p.patientId,
                                );
                              },
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
                  const SizedBox(height: 12),
                ],
                if (_patientCount == 0) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.doctorPatientSetup)
                          .then((_) => _load());
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Link a patient with code'),
                  ),
                  const SizedBox(height: 12),
                ],
                QuickNavWrap(
                  routes: {
                    'Patient List': AppRoutes.doctorPatientList,
                    if (_patientCount > 0)
                      'Open Patient History': AppRoutes.doctorPatientHistory,
                    'Settings': AppRoutes.settings,
                  },
                ),
              ],
            ),
    );
  }
}
