import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_session.dart';
import '../i18n/app_language.dart';
import '../navigation/app_routes.dart';
import '../reminders/medication_alarm_scheduler.dart';
import '../reminders/medication_notification_service.dart';
import 'auth_session_store.dart';

/// Signs out and returns to role selection (phone login on next sign-in).
abstract final class AuthLogout {
  static Future<void> confirmAndSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLanguageState.pick(en: 'Log out?', ur: 'لاگ آؤٹ کریں؟'),
        ),
        content: Text(
          AppLanguageState.pick(
            en: 'You will need your phone number to sign in again.',
            ur: 'دوبارہ سائن ان کے لیے فون نمبر درکار ہوگا۔',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLanguageState.pick(en: 'Cancel', ur: 'منسوخ')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLanguageState.pick(en: 'Log out', ur: 'لاگ آؤٹ')),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;
    await signOut(context);
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await MedicationNotificationService.instance.cancelAllDoseReminders();
      MedicationAlarmScheduler.instance.stop();
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Still clear local session if network sign-out fails.
    }

    await AuthSessionStore.clear();
    AppSession.clear();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelect,
      (route) => false,
    );
  }
}
