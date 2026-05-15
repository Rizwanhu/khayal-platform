import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';

import '../../common/widgets/screen_helpers.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<PatientHistoryRecord> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId =
        AppSession.selectedPatientId ??
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing patient session. Login with phone OTP first.';
      });
      return;
    }
    try {
      final data = await Backend.repo.getPatientHistory(patientId);
      if (!mounted) return;
      setState(() {
        _rows = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load history: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: 'SCR-011 · Patient History',
      subtitle: 'Live data from Supabase',
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Text(_error!)
              : Column(
                children:
                    _rows
                        .map(
                          (r) => HistoryRow(day: r.dayLabel, status: r.status),
                        )
                        .toList(),
              ),
    );
  }
}
