import 'package:flutter/material.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/ui/doctor_ui_tokens.dart';
import '../../../core/ui/doctor_ui_widgets.dart';
import '../../../widgets/doctor_shell_scaffold.dart';

/// Doctor enters patient phone + link code from the patient home key icon.
class DoctorPatientSetupScreen extends StatefulWidget {
  const DoctorPatientSetupScreen({super.key});

  @override
  State<DoctorPatientSetupScreen> createState() =>
      _DoctorPatientSetupScreenState();
}

class _DoctorPatientSetupScreenState extends State<DoctorPatientSetupScreen> {
  final _patientPhoneController = TextEditingController();
  final _linkCodeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _patientPhoneController.dispose();
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCodeAndLinkPatient() async {
    final doctorId = AppSession.currentUserId;
    final patientPhone = _patientPhoneController.text.trim();
    final code = _linkCodeController.text.trim();
    if (doctorId == null || doctorId.isEmpty) {
      _toast('Session missing. Login again.');
      return;
    }
    if (patientPhone.isEmpty || code.isEmpty) {
      _toast('Enter patient phone and link code.');
      return;
    }
    setState(() => _saving = true);
    try {
      final normalizedPhone = patientPhone.startsWith('+')
          ? patientPhone
          : '+$patientPhone';
      final linked = await Backend.repo.linkDoctorToPatientViaCode(
        doctorId: doctorId,
        patientPhone: normalizedPhone,
        code: code,
      );
      if (!linked) {
        _toast('Invalid/expired code or patient not found.');
        return;
      }
      if (!mounted) return;
      final patientId = await Backend.repo.getFirstPatientForDoctor(doctorId);
      AppSession.setRole(
        role: AppRole.doctor,
        userId: doctorId,
        patientId: patientId,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.doctorDashboard,
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
    return DoctorShellScaffold(
      title: 'Link patient',
      subtitle: 'Phone + code from patient app',
      body: Padding(
        padding: const EdgeInsets.all(DoctorUiTokens.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ask the patient to tap the key icon on their home screen and share the 6-digit code.',
              style: DoctorUiTokens.bodyStyle(),
            ),
            const SizedBox(height: DoctorUiTokens.gapSection),
            TextField(
              controller: _patientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Patient phone (e.g. +923001234567)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-digit link code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            DoctorUi.primaryButton(
              label: _saving ? 'Linking…' : 'Verify & link patient',
              icon: Icons.link_rounded,
              onPressed: _saving ? null : _verifyCodeAndLinkPatient,
            ),
          ],
        ),
      ),
    );
  }
}
