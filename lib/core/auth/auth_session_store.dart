import 'package:shared_preferences/shared_preferences.dart';

import '../backend/app_session.dart';

/// Persists last signed-in role so cold start can skip onboarding when Supabase session is valid.
abstract final class AuthSessionStore {
  static const _keyRole = 'auth_last_role';

  static Future<void> saveRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role.name);
  }

  static Future<AppRole?> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRole);
    return switch (raw) {
      'patient' => AppRole.patient,
      'caregiver' => AppRole.caregiver,
      'doctor' => AppRole.doctor,
      _ => null,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRole);
  }
}
