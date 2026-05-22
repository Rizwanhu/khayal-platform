import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_env.dart';
import 'core/i18n/app_language.dart';
import 'core/navigation/app_routes.dart';
import 'core/reminders/medication_alarm_scheduler.dart';
import 'core/reminders/medication_notification_service.dart';
import 'core/reminders/reminder_preferences.dart';
import 'core/theme/app_theme.dart';
import 'widgets/med_alarm_lifecycle_host.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await AppLanguageState.loadFromDisk();
  await ReminderPreferences.loadFromDisk();
  if (!kIsWeb) {
    MedicationNotificationService.navigatorKey = rootNavigatorKey;
    MedicationAlarmScheduler.instance.attachNavigator(rootNavigatorKey);
    await MedicationNotificationService.instance.initialize();
  }
  if (kDebugMode) {
    debugPrint(
      'khayal_platform: DEV_OTP_BYPASS=${AppEnv.devOtpBypass} '
      '(.env or --dart-define=DEV_OTP_BYPASS=true)',
    );
  }
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  assert(() {
    if (AppEnv.supabaseUrl.contains('YOUR_PROJECT_REF')) {
      debugPrint(
        'khayal_platform: Supabase URL still placeholder — update .env (see README).',
      );
    }
    return true;
  }());
  runApp(
    const MedAlarmLifecycleHost(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageState.localeRevision,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Khayal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          routes: appRoutes,
        );
      },
    );
  }
}
