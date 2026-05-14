import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_repository.dart';

abstract final class Backend {
  static SupabaseClient get client => Supabase.instance.client;

  static BackendRepository get repo => BackendRepository(client);
}
