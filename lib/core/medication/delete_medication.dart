import 'package:flutter/material.dart';

import '../backend/backend.dart';
import '../i18n/app_language.dart';
import '../reminders/medication_notification_service.dart';
import 'med_patient_context.dart';

/// Confirms with the user, deletes the medication in Supabase, and resyncs dose alarms.
Future<bool> confirmAndDeleteMedication(
  BuildContext context, {
  required String medicationId,
  required String nameEn,
  required String nameUr,
}) async {
  final displayName = AppLanguageState.pick(en: nameEn, ur: nameUr);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        'Remove medicine?',
        style: TextStyle(fontFamily: 'KhayalRoboto', fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Remove "$displayName" from your list? Reminders for this medicine will stop.',
        style: const TextStyle(fontFamily: 'KhayalRoboto'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await Backend.repo.deleteMedication(medicationId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove medicine: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  final patientId = await MedPatientContext.resolvePatientId();
  if (patientId != null && MedPatientContext.isPatient) {
    try {
      final meds = await Backend.repo.getMedicationsForPatient(patientId);
      await MedicationNotificationService.instance.syncSchedules(
        patientId: patientId,
        meds: meds,
      );
    } catch (e) {
      debugPrint('khayal_platform: alarm reschedule after delete: $e');
    }
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$displayName" removed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return true;
}
