import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../chat/chat_conversation_panel.dart';

/// Doctor ↔ patient chat (free for doctors).
class DoctorPatientChatScreen extends StatefulWidget {
  const DoctorPatientChatScreen({super.key, this.patientId});

  /// When null, uses [AppSession.selectedPatientId].
  final String? patientId;

  @override
  State<DoctorPatientChatScreen> createState() =>
      _DoctorPatientChatScreenState();
}

class _DoctorPatientChatScreenState extends State<DoctorPatientChatScreen> {
  bool _loading = true;
  String? _error;
  String? _threadId;
  String? _patientName;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doctorId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    final patientId = widget.patientId ?? AppSession.selectedPatientId;
    if (doctorId == null ||
        doctorId.isEmpty ||
        patientId == null ||
        patientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Select a patient first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _doctorId = doctorId;
    });

    try {
      final profile = await Backend.repo.getPatientProfile(patientId);
      final thread = await Backend.chat.getOrCreateThread(
        doctorId: doctorId,
        patientId: patientId,
      );
      if (!mounted) return;
      setState(() {
        _patientName = profile?.fullName ?? 'Patient';
        _threadId = thread.id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_patientName ?? 'Patient chat'),
            Text(
              'Included for doctors',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
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
          : _threadId == null
          ? const Center(child: Text('Could not open chat.'))
          : ChatConversationPanel(
              threadId: _threadId!,
              currentUserId: _doctorId!,
              peerName: _patientName ?? 'Patient',
            ),
    );
  }
}
