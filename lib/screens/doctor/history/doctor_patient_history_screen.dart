import 'package:flutter/material.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/medication/dose_missed_sync.dart';
import '../../../core/navigation/app_routes.dart';
import '../../common/widgets/screen_helpers.dart';

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
          _error = 'No patient selected. Link a patient in Settings.';
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

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'Patient history',
      subtitle: _patientName.isNotEmpty
          ? 'Adherence for $_patientName'
          : 'Dose history for your patient',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_error!),
                if (_allPatients.isEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.doctorPatientSetup,
                      ).then((_) => _load());
                    },
                    child: const Text('Add patient'),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_allPatients.length > 1) ...[
                  DropdownButtonFormField<String>(
                    value: AppSession.selectedPatientId,
                    decoration: const InputDecoration(
                      labelText: 'Patient',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                ] else
                  InfoTile(label: 'Patient', value: _patientName),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    final id = AppSession.selectedPatientId;
                    if (id == null) return;
                    Navigator.pushNamed(
                      context,
                      AppRoutes.doctorPatientChat,
                      arguments: id,
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message patient'),
                ),
                const SizedBox(height: 16),
                if (_rows.isEmpty)
                  const Text('No dose history recorded yet.')
                else
                  ..._rows.map(
                    (r) => HistoryRow(day: r.dayLabel, status: r.status),
                  ),
              ],
            ),
    );
  }
}
