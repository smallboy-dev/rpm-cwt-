// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import 'chat_repository.dart';

class SupabaseChatRepository extends ChatRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Stream<List<ChatMessage>> getMessageStream(String projectId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('timestamp', ascending: true)
        .map((maps) => maps.map((map) => ChatMessage.fromJson(map)).toList());
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    try {
      final data = message.toJson();
      if (data['id'] != null && data['id'].length < 32) {
        data.remove('id');
      }
      await _supabase.from('messages').insert(data);
    } catch (e) {
      print('DEBUG: Supabase sendMessage Error: $e');
      rethrow;
    }
  }
}
