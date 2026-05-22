import 'package:supabase_flutter/supabase_flutter.dart';
import '../billing/chat_billing_service.dart';
import '../chat/chat_repository.dart';
import 'backend_repository.dart';
export 'backend_repository.dart';

abstract final class Backend {
  static SupabaseClient get client => Supabase.instance.client;

  static BackendRepository get repo => BackendRepository(client);

  static ChatRepository get chat => ChatRepository(client);

  static ChatBillingService get chatBilling => ChatBillingService(client);
}
