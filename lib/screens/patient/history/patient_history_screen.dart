import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/ui/patient_shell_colors.dart';
import '../../../core/ui/patient_ui_tokens.dart';
import '../../../core/ui/patient_ui_widgets.dart';
import '../../../core/ui/user_facing_error.dart';

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
        _error = AppLanguageState.pick(
          en: 'Please sign in with your phone number first.',
          ur: 'پہلے فون نمبر سے سائن ان کریں۔',
        );
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
        _error = userFacingNetworkOrGenericError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientShellColors.canvas,
      appBar: PatientUi.appBar(
        title: AppLanguageState.pick(en: 'Dose history', ur: 'دوا کی تاریخ'),
      ),
      body: _loading
          ? PatientUi.loadingPanel(
              title: AppLanguageState.pick(
                en: 'Loading history…',
                ur: 'تاریخ لوڈ ہو رہی ہے…',
              ),
            )
          : _error != null
          ? PatientUi.messagePanel(
              icon: Icons.error_outline_rounded,
              iconColor: PatientShellColors.missed,
              iconBg: const Color(0xFFFFEBEE),
              title: AppLanguageState.pick(
                en: 'Could not load history',
                ur: 'تاریخ نہیں کھلی',
              ),
              message: _error!,
              primaryLabel: AppLanguageState.pick(
                en: 'Try again',
                ur: 'دوبارہ کوشش',
              ),
              onPrimary: _load,
            )
          : _rows.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  AppLanguageState.pick(
                    en: 'No doses recorded yet.',
                    ur: 'ابھی کوئی ریکارڈ نہیں۔',
                  ),
                  textAlign: TextAlign.center,
                  style: PatientUiTokens.bodyStyle(
                    urdu: AppLanguageState.isUrdu,
                    color: PatientShellColors.textSecondary,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(PatientUiTokens.paddingScreen),
              itemCount: _rows.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: PatientUiTokens.gapItem),
              itemBuilder: (context, i) {
                final r = _rows[i];
                final statusColor = switch (r.status) {
                  'Taken' => PatientShellColors.taken,
                  'Missed' => PatientShellColors.missed,
                  _ => PatientShellColors.upcoming,
                };
                return Material(
                  color: PatientShellColors.card,
                  borderRadius: BorderRadius.circular(
                    PatientUiTokens.radiusCard,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    minVerticalPadding: 14,
                    title: Text(
                      r.dayLabel,
                      style: PatientUiTokens.bodyStyle(
                        urdu: AppLanguageState.isUrdu,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    trailing: Text(
                      r.status,
                      style: PatientUiTokens.labelStyle(
                        urdu: AppLanguageState.isUrdu,
                        color: statusColor,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
