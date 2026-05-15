import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_env.dart';
import 'core/i18n/app_language.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await AppLanguageState.loadFromDisk();
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageState.localeRevision,
      builder: (context, _) {
        return MaterialApp(
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
