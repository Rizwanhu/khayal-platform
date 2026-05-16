import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_env.dart';
import 'chat_models.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  Future<bool> isPatientSubscribed(String patientId) async {
    if (AppEnv.devChatSubscriptionBypass) return true;
    final sub = await getSubscription(patientId);
    return sub?.isActive ?? false;
  }

  Future<PatientChatSubscription?> getSubscription(String patientId) async {
    try {
      final row = await _client
          .from('patient_chat_subscriptions')
          .select('status,current_period_end')
          .eq('patient_id', patientId)
          .maybeSingle();
      if (row == null) return null;
      final endRaw = row['current_period_end'];
      return PatientChatSubscription(
        status: (row['status'] ?? 'inactive').toString(),
        currentPeriodEnd: endRaw == null
            ? null
            : DateTime.tryParse(endRaw.toString())?.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<LinkedDoctorInfo?> getLinkedDoctorForPatient(String patientId) async {
    final link = await _client
        .from('doctor_patient_links')
        .select('doctor_id')
        .eq('patient_id', patientId)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();
    if (link == null) return null;

    final doctorId = link['doctor_id'].toString();
    final profile = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', doctorId)
        .maybeSingle();
    final name = (profile?['full_name'] ?? 'Your doctor').toString();
    return LinkedDoctorInfo(doctorId: doctorId, doctorName: name);
  }

  Future<ChatThread> getOrCreateThread({
    required String doctorId,
    required String patientId,
  }) async {
    final existing = await _client
        .from('chat_threads')
        .select('id,doctor_id,patient_id')
        .eq('doctor_id', doctorId)
        .eq('patient_id', patientId)
        .maybeSingle();
    if (existing != null) {
      return ChatThread(
        id: existing['id'].toString(),
        doctorId: existing['doctor_id'].toString(),
        patientId: existing['patient_id'].toString(),
      );
    }

    final inserted = await _client
        .from('chat_threads')
        .insert({'doctor_id': doctorId, 'patient_id': patientId})
        .select('id,doctor_id,patient_id')
        .single();
    return ChatThread(
      id: inserted['id'].toString(),
      doctorId: inserted['doctor_id'].toString(),
      patientId: inserted['patient_id'].toString(),
    );
  }

  Future<List<ChatMessage>> listMessages(String threadId, {int limit = 80}) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('chat_messages')
          .select('id,thread_id,sender_id,body,created_at')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true)
          .limit(limit),
    );
    return rows.map(_messageFromRow).toList();
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
    final row = await _client
        .from('chat_messages')
        .insert({
          'thread_id': threadId,
          'sender_id': senderId,
          'body': trimmed,
        })
        .select('id,thread_id,sender_id,body,created_at')
        .single();
    return _messageFromRow(row);
  }

  RealtimeChannel subscribeToThread(
    String threadId, {
    required void Function(ChatMessage message) onInsert,
  }) {
    return _client
        .channel('chat-thread-$threadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            onInsert(_messageFromRow(Map<String, dynamic>.from(record)));
          },
        )
        .subscribe();
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'].toString(),
      threadId: row['thread_id'].toString(),
      senderId: row['sender_id'].toString(),
      body: row['body'].toString(),
      createdAt: DateTime.parse(row['created_at'].toString()).toUtc(),
    );
  }
}
