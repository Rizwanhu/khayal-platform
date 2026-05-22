import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_session.dart';
import '../backend/backend.dart';

/// Resolves which patient’s medications the current user may manage.
abstract final class MedPatientContext {
  static bool get isPatient => AppSession.currentRole == AppRole.patient;

  static String? get actorId =>
      AppSession.currentUserId ??
      Supabase.instance.client.auth.currentUser?.id;

  static Future<String?> resolvePatientId() async {
    final userId = actorId;
    if (userId == null || userId.isEmpty) return null;

    if (isPatient) return userId;

    final cached = AppSession.selectedPatientId;
    if (cached != null && cached.isNotEmpty) return cached;

    final linked = await Backend.repo.getFirstPatientForCaregiver(userId);
    AppSession.selectedPatientId = linked;
    return linked;
  }
}
