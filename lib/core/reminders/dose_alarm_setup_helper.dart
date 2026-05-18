import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../i18n/app_language.dart';
import 'medication_notification_service.dart';

/// Guides the user through Android settings so dose alarms work when the app is swiped away.
class DoseAlarmSetupHelper {
  DoseAlarmSetupHelper._();

  static Future<bool> exactAlarmsGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final android = MedicationNotificationService.instance
        .androidImplementation;
    return await android?.canScheduleExactNotifications() ?? true;
  }

  static Future<void> requestExactAlarms() async {
    await MedicationNotificationService.instance.requestAndroidPermissions(
      force: true,
    );
  }

  static Future<void> openExactAlarmSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.alarm);
  }

  static Future<void> openBatteryOptimization() async {
    await AppSettings.openAppSettings(
      type: AppSettingsType.batteryOptimization,
    );
  }

  static Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  static Future<void> showSetupSheet(BuildContext context) async {
    final exactOk = await exactAlarmsGranted();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLanguageState.pick(
                    en: 'Alarms when app is closed',
                    ur: 'ایپ بند ہونے پر بھی الارم',
                  ),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLanguageState.pick(
                    en:
                        'For loud medicine alarms when the app is closed: allow exact alarms and set Khayal battery to Unrestricted. You do not need Do Not Disturb settings — ignore that screen if your phone opens it. On Samsung/Infinix: also allow notifications and disable battery limits for Khayal.',
                    ur:
                        'ایپ بند ہونے پر الارم کے لیے exact alarms اور Khayal کی battery Unrestricted کریں۔ Do Not Disturb کی ضرورت نہیں۔ Samsung/Infinix پر notifications اور battery limit بھی چیک کریں۔',
                  ),
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                if (!exactOk) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await requestExactAlarms();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.alarm),
                    label: Text(
                      AppLanguageState.pick(
                        en: 'Allow exact alarms',
                        ur: 'Exact alarms کی اجازت',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await openBatteryOptimization();
                  },
                  icon: const Icon(Icons.battery_charging_full),
                  label: Text(
                    AppLanguageState.pick(
                      en: 'Battery / background settings',
                      ur: 'بیٹری / پس منظر کی ترتیبات',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLanguageState.pick(en: 'Done', ur: 'ٹھیک ہے')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
