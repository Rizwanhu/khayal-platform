import 'package:flutter/material.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_repository.dart';
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
  List<PatientHistoryRecord> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = AppSession.selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Select a patient first.';
      });
      return;
    }
    try {
      final history = await Backend.repo.getPatientHistory(patientId);
      setState(() {
        _rows = history;
        _loading = false;
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
      title: 'Doctor Patient History',
      subtitle: 'Read-only adherence and dose history (live)',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Text(_error!)
          : Column(
              children: [
                InfoTile(
                  label: 'Patient ID',
                  value: AppSession.selectedPatientId ?? '-',
                ),
                const SizedBox(height: 10),
                ..._rows.map(
                  (r) => HistoryRow(day: r.dayLabel, status: r.status),
                ),
              ],
            ),
    );
  }
}
