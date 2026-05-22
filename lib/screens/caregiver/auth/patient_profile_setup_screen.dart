import 'package:flutter/material.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';

class PatientProfileSetupScreen extends StatefulWidget {
  const PatientProfileSetupScreen({super.key});

  @override
  State<PatientProfileSetupScreen> createState() =>
      _PatientProfileSetupScreenState();
}

class _PatientProfileSetupScreenState extends State<PatientProfileSetupScreen> {
  final _patientPhoneController = TextEditingController();
  final _linkCodeController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _continueIfPatientAlreadyLinked();
    });
  }

  /// After hot reload, skip re-linking when this caregiver already has a patient.
  Future<void> _continueIfPatientAlreadyLinked() async {
    final caregiverId = AppSession.currentUserId;
    if (caregiverId == null || caregiverId.isEmpty) return;
    final patientId = await Backend.repo.getFirstPatientForCaregiver(caregiverId);
    if (patientId == null || !mounted) return;
    AppSession.setRole(
      role: AppRole.caregiver,
      userId: caregiverId,
      patientId: patientId,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.caregiverDashboard);
  }

  @override
  void dispose() {
    _patientPhoneController.dispose();
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCodeAndLinkPatient() async {
    final caregiverId = AppSession.currentUserId;
    final patientPhone = _patientPhoneController.text.trim();
    final code = _linkCodeController.text.trim();
    if (caregiverId == null || caregiverId.isEmpty) {
      _toast('Session missing. Login again.');
      return;
    }
    if (patientPhone.isEmpty || code.isEmpty) {
      _toast('Enter patient phone and link code.');
      return;
    }
    setState(() => _saving = true);
    try {
      final normalizedPhone =
          patientPhone.startsWith('+') ? patientPhone : '+$patientPhone';
      final linked = await Backend.repo.linkCaregiverToPatientViaCode(
        caregiverId: caregiverId,
        patientPhone: normalizedPhone,
        code: code,
      );
      if (!linked) {
        _toast('Invalid/expired code or patient not found.');
        return;
      }
      if (!mounted) return;
      final patientId = await Backend.repo.getFirstPatientForCaregiver(
        caregiverId,
      );
      AppSession.setRole(
        role: AppRole.caregiver,
        userId: caregiverId,
        patientId: patientId,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.caregiverDashboard,
        (route) => false,
      );
    } catch (e) {
      _toast('Link failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _patientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Patient Phone (e.g. +923001234567)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _linkCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-digit link code from patient',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _verifyCodeAndLinkPatient,
                child: Text(_saving ? 'Linking...' : 'Link patient & continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
