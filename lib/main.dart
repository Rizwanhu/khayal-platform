import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_env.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
    return MaterialApp(
      title: 'Khayal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: appRoutes,
    );
  }
}
