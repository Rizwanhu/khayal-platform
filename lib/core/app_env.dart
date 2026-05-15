import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'backend/app_session.dart';

/// Reads configuration from `.env` (loaded in [main]).
/// Values are empty strings until you create `.env` from `.env.example`.
abstract final class AppEnv {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// **TEMPORARY QA ONLY.** When `true`, the OTP screen skips real SMS/verify and
  /// signs in with [bypassEmailPasswordForRole] using any 6 digits as the "code".
  /// Remove or set `false` before any public release.
  static bool get devOtpBypass =>
      (dotenv.env['DEV_OTP_BYPASS'] ?? '').toLowerCase() == 'true';

  /// Returns `(email, password)` for [role] when [devOtpBypass] is enabled and env is set.
  static (String email, String password)? bypassEmailPasswordForRole(
    AppRole role,
  ) {
    if (!devOtpBypass) return null;
    final (keyE, keyP) = switch (role) {
      AppRole.patient => (
        'DEV_BYPASS_PATIENT_EMAIL',
        'DEV_BYPASS_PATIENT_PASSWORD',
      ),
      AppRole.caregiver => (
        'DEV_BYPASS_CAREGIVER_EMAIL',
        'DEV_BYPASS_CAREGIVER_PASSWORD',
      ),
      AppRole.doctor => (
        'DEV_BYPASS_DOCTOR_EMAIL',
        'DEV_BYPASS_DOCTOR_PASSWORD',
      ),
    };
    final email = dotenv.env[keyE]?.trim() ?? '';
    final password = dotenv.env[keyP]?.trim() ?? '';
    if (email.isEmpty || password.isEmpty) return null;
    return (email, password);
  }
}
