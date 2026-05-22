import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'backend/app_session.dart';

/// Reads configuration from `.env` (loaded in [main]).
/// Values are empty strings until you create `.env` from `.env.example`.
abstract final class AppEnv {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Shared password for phone-only sign-in ([BackendRepository.signInOrSignUpWithPhone]).
  /// Each phone maps to a synthetic Supabase email. Disable email confirmation in Auth settings.
  static String get phoneAuthPassword =>
      dotenv.env['PHONE_AUTH_PASSWORD']?.trim() ?? '';

  /// **TEMPORARY QA ONLY.** When `true`, the phone screen skips phone auth and uses
  /// [bypassEmailPasswordForRole] instead. Remove or set `false` before release.
  ///
  /// Enable via either:
  /// - `.env`: `DEV_OTP_BYPASS=true` (then **full restart** the app — hot reload is not enough), or
  /// - `flutter run --dart-define=DEV_OTP_BYPASS=true` (no `.env` change).
  static bool get devOtpBypass {
    if (const bool.fromEnvironment('DEV_OTP_BYPASS', defaultValue: false)) {
      return true;
    }
    final v = (dotenv.env['DEV_OTP_BYPASS'] ?? '').trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  /// Returns `(email, password)` for [role] when [devOtpBypass] is enabled and env is set.
  ///
  /// Prefer role-specific `DEV_BYPASS_*_EMAIL` / `PASSWORD`. If those are empty,
  /// falls back to a single [DEV_BYPASS_EMAIL] / [DEV_BYPASS_PASSWORD] (one Supabase
  /// Auth user for quick smoke tests).
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
    var email = dotenv.env[keyE]?.trim() ?? '';
    var password = dotenv.env[keyP]?.trim() ?? '';
    if (email.isEmpty || password.isEmpty) {
      email = dotenv.env['DEV_BYPASS_EMAIL']?.trim() ?? '';
      password = dotenv.env['DEV_BYPASS_PASSWORD']?.trim() ?? '';
    }
    if (email.isEmpty || password.isEmpty) return null;
    return (email, password);
  }

  /// Monthly doctor–patient chat price shown in the app (PKR).
  static int get chatMonthlyPricePkr {
    final raw = dotenv.env['CHAT_MONTHLY_PRICE_PKR']?.trim();
    return int.tryParse(raw ?? '') ?? 1000;
  }

  /// Optional Stripe Payment Link (fallback if Edge Function is not deployed).
  static String? get chatStripePaymentLink {
    final v = dotenv.env['CHAT_STRIPE_PAYMENT_LINK']?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  /// QA: treat patient as subscribed without Stripe (`DEV_CHAT_SUBSCRIPTION_ACTIVE=true`).
  static bool get devChatSubscriptionBypass {
    if (const bool.fromEnvironment(
      'DEV_CHAT_SUBSCRIPTION_ACTIVE',
      defaultValue: false,
    )) {
      return true;
    }
    final v =
        (dotenv.env['DEV_CHAT_SUBSCRIPTION_ACTIVE'] ?? '').trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
}
