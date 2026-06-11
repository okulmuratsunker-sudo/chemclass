import '../core/supabase_config.dart';
import '../state/realtime_list.dart';
import 'models.dart';

/// All messages for a class, kept in sync via Realtime. Use [threadWith] to
/// get the 1:1 conversation between [currentUserId] and another user.
class ClassMessagesController extends RealtimeListController<Message> {
  ClassMessagesController({required String classId})
      : super(
          table: 'messages',
          fromJson: Message.fromJson,
          match: {'class_id': classId},
          compare: (a, b) => a.createdAt.compareTo(b.createdAt),
        );

  List<Message> threadWith(String currentUserId, String peerId) {
    return items
        .where((m) =>
            (m.senderId == peerId && m.recipientId == currentUserId) ||
            (m.senderId == currentUserId && m.recipientId == peerId))
        .toList();
  }
}

Future<Object?> sendMessage({
  required String classId,
  required String senderId,
  required String? recipientId,
  required String content,
}) async {
  try {
    await supabase.from('messages').insert({
      'class_id': classId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
    });
    return null;
  } catch (e) {
    return e;
  }
}

Future<void> markMessagesRead(List<String> ids) async {
  if (ids.isEmpty) return;
  await supabase.from('messages').update({'read_at': DateTime.now().toIso8601String()}).inFilter('id', ids);
}
