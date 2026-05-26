import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_env.dart';
import 'chat_models.dart';

const chatImagesBucket = 'chat-images';

const _messageSelectWithImage =
    'id,thread_id,sender_id,body,created_at,image_storage_path';
const _messageSelectLegacy = 'id,thread_id,sender_id,body,created_at';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  /// null = unknown, true/false after first query.
  bool? _imageColumnAvailable;

  bool _isMissingImageColumnError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('image_storage_path') &&
        (s.contains('42703') || s.contains('does not exist'));
  }

  String get _messageSelect =>
      _imageColumnAvailable == false
          ? _messageSelectLegacy
          : _messageSelectWithImage;

  Future<List<ChatMessage>> listMessages(String threadId, {int limit = 80}) async {
    try {
      final rows = List<Map<String, dynamic>>.from(
        await _client
            .from('chat_messages')
            .select(_messageSelect)
            .eq('thread_id', threadId)
            .order('created_at', ascending: true)
            .limit(limit),
      );
      if (_messageSelect == _messageSelectWithImage) {
        _imageColumnAvailable = true;
      }
      return rows.map(_messageFromRow).toList();
    } catch (e) {
      if (_imageColumnAvailable != false && _isMissingImageColumnError(e)) {
        _imageColumnAvailable = false;
        return listMessages(threadId, limit: limit);
      }
      rethrow;
    }
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
    try {
      final row = await _client
          .from('chat_messages')
          .insert({
            'thread_id': threadId,
            'sender_id': senderId,
            'body': trimmed,
          })
          .select(_messageSelect)
          .single();
      return _messageFromRow(row);
    } catch (e) {
      if (_imageColumnAvailable != false && _isMissingImageColumnError(e)) {
        _imageColumnAvailable = false;
        return sendMessage(
          threadId: threadId,
          senderId: senderId,
          body: body,
        );
      }
      rethrow;
    }
  }

  Future<ChatMessage> sendImageMessage({
    required String threadId,
    required String senderId,
    required Uint8List bytes,
    required String contentType,
    String? caption,
  }) async {
    if (_imageColumnAvailable == false) {
      throw StateError(
        'Photo chat is not set up yet. Ask your admin to run '
        'supabase/sql/chat_messages_images.sql in Supabase.',
      );
    }

    final messageId =
        '${DateTime.now().millisecondsSinceEpoch}-${senderId.hashCode.abs()}';
    final ext = _imageExtensionForContentType(contentType);
    final path = '$threadId/$messageId.$ext';

    try {
      await _client.storage.from(chatImagesBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final row = await _client
          .from('chat_messages')
          .insert({
            'thread_id': threadId,
            'sender_id': senderId,
            'body': caption?.trim() ?? '',
            'image_storage_path': path,
          })
          .select(_messageSelectWithImage)
          .single();
      _imageColumnAvailable = true;
      return _messageFromRow(row);
    } catch (e) {
      if (_isMissingImageColumnError(e)) {
        _imageColumnAvailable = false;
        throw StateError(
          'Photo chat is not set up yet. Run chat_messages_images.sql in Supabase.',
        );
      }
      rethrow;
    }
  }

  Future<String?> signedChatImageUrl(
    String? imageStoragePath, {
    int expiresInSeconds = 3600,
  }) async {
    if (imageStoragePath == null || imageStoragePath.isEmpty) return null;
    if (_imageColumnAvailable == false) return null;
    return _client.storage
        .from(chatImagesBucket)
        .createSignedUrl(imageStoragePath, expiresInSeconds);
  }

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

  String _imageExtensionForContentType(String contentType) {
    final lower = contentType.toLowerCase();
    if (lower.contains('png')) return 'png';
    if (lower.contains('webp')) return 'webp';
    return 'jpg';
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row) {
    final img = row['image_storage_path'];
    return ChatMessage(
      id: row['id'].toString(),
      threadId: row['thread_id'].toString(),
      senderId: row['sender_id'].toString(),
      body: row['body'].toString(),
      createdAt: DateTime.parse(row['created_at'].toString()).toUtc(),
      imageStoragePath: img?.toString(),
    );
  }
}
