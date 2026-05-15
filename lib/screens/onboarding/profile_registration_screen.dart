import 'package:flutter/material.dart';

import '../../core/backend/app_session.dart';
import '../../core/backend/backend.dart';
import '../../core/navigation/app_routes.dart';

/// Collects full name after phone sign-in for patient and doctor (caregiver uses
/// [CaregiverRegistrationScreen] with extra fields).
class ProfileRegistrationScreen extends StatefulWidget {
  const ProfileRegistrationScreen({super.key});

  @override
  State<ProfileRegistrationScreen> createState() =>
      _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  AppRole get _role => AppSession.currentRole ?? AppRole.patient;

  String get _title => switch (_role) {
        AppRole.patient => 'Patient registration',
        AppRole.doctor => 'Doctor registration',
        AppRole.caregiver => 'Registration',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _skipIfAlreadyRegistered();
      _prefillPhone();
    });
  }

  Future<void> _prefillPhone() async {
    final userId = AppSession.currentUserId;
    if (userId == null) return;
    final profile = await Backend.repo.getPatientProfile(userId);
    final phone = profile?.phone?.trim();
    if (phone != null && phone.isNotEmpty && mounted) {
      _phoneController.text = phone;
    }
  }

  Future<void> _skipIfAlreadyRegistered() async {
    final userId = AppSession.currentUserId;
    if (userId == null || userId.isEmpty) return;
    final complete = await _isProfileComplete(userId);
    if (!complete || !mounted) return;
    _goToRoleHome(userId, replace: true);
  }

  Future<bool> _isProfileComplete(String userId) => switch (_role) {
        AppRole.patient => Backend.repo.patientProfileIsComplete(userId),
        AppRole.doctor => Backend.repo.doctorProfileIsComplete(userId),
        AppRole.caregiver => Backend.repo.caregiverProfileIsComplete(userId),
      };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final userId = AppSession.currentUserId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session missing. Please sign in again.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelect,
        (r) => false,
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your full name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final phoneRaw = _phoneController.text.trim();
      await Backend.repo.upsertProfile(
        userId: userId,
        role: _role.name,
        fullName: name,
        phone: phoneRaw.isEmpty
            ? null
            : BackendRepository.normalizePhone(phoneRaw) ?? phoneRaw,
      );
      if (!mounted) return;
      _goToRoleHome(userId, replace: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _goToRoleHome(String userId, {required bool replace}) async {
    void go(String route) {
      if (!mounted) return;
      if (replace) {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      }
    }

    switch (_role) {
      case AppRole.patient:
        AppSession.setRole(
          role: AppRole.patient,
          userId: userId,
          patientId: userId,
        );
        go(AppRoutes.patientHome);
        break;
      case AppRole.doctor:
        final patientId = await Backend.repo.getFirstPatientForDoctor(userId);
        if (!mounted) return;
        AppSession.setRole(
          role: AppRole.doctor,
          userId: userId,
          patientId: patientId,
        );
        go(
          patientId != null
              ? AppRoutes.doctorDashboard
              : AppRoutes.doctorPatientSetup,
        );
        break;
      case AppRole.caregiver:
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.caregiverRegistration,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _role == AppRole.doctor
                  ? 'Add your name so patients and caregivers know who you are.'
                  : 'Add your name so your caregiver and doctor can recognize you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional if already set)',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAndContinue,
                child: Text(_saving ? 'Saving…' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
