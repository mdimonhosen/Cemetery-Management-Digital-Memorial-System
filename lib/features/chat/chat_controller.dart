import 'package:cemetry/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatControllerProvider = Provider((ref) => ChatController());

final userChatRequestProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return const Stream.empty();

  return supabase
      .from('chat_requests')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.isNotEmpty ? data.first : null);
});

final pendingChatRequestsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('chat_requests')
      .stream(primaryKey: ['id'])
      .eq('status', 'pending')
      .map((data) => data);
});

final approvedChatRequestsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('chat_requests')
      .stream(primaryKey: ['id'])
      .eq('status', 'approved')
      .order('created_at', ascending: false)
      .map((data) => data);
});

final chatMessagesProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, requestId) {
  return supabase
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('chat_request_id', requestId)
      .order('created_at', ascending: true)
      .map((data) => data);
});

final profileByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  return await supabase.from('profiles').select().eq('id', id).maybeSingle();
});

final allAdminsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await supabase.from('profiles').select().eq('count', 1);
  return List<Map<String, dynamic>>.from(response);
});

class ChatController {
  ChatController();

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<void> requestChat({String? adminId}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Check if there's already an active (pending or approved) request
    final existing = await supabase
        .from('chat_requests')
        .select()
        .eq('user_id', user.id)
        .or('status.eq.pending,status.eq.approved')
        .maybeSingle();

    if (existing != null) {
      throw Exception('You already have an active chat session or request.');
    }

    try {
      await supabase.from('chat_requests').insert({
        'user_id': user.id,
        'admin_id': adminId,
        'status': 'pending',
      });
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
         return;
      }
      rethrow;
    }
  }

  Future<void> approveChat(String requestId) async {
    await supabase.from('chat_requests').update({'status': 'approved'}).eq('id', requestId);
  }

  Future<void> rejectChat(String requestId) async {
    await supabase.from('chat_requests').update({'status': 'rejected'}).eq('id', requestId);
  }

  Future<void> sendMessage(String requestId, String text) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('chat_messages').insert({
      'chat_request_id': requestId,
      'sender_id': user.id,
      'text': text,
    });
  }
}
