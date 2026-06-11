import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/classes_repository.dart';
import '../../data/messages_repository.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';

class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassRosterController(classId)),
        ChangeNotifierProvider(create: (_) => ClassMessagesController(classId: classId)),
      ],
      child: _MessagesInboxView(classId: classId),
    );
  }
}

class _MessagesInboxView extends StatelessWidget {
  const _MessagesInboxView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final teacherId = context.watch<AuthState>().profile?.id;
    final rosterController = context.watch<ClassRosterController>();
    final messagesController = context.watch<ClassMessagesController>();

    if (rosterController.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mesajlar')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final conversations = rosterController.roster.map((entry) {
      final thread = teacherId == null ? <Message>[] : messagesController.threadWith(teacherId, entry.studentId);
      final lastMessage = thread.isEmpty ? null : thread.last;
      final unreadCount =
          thread.where((m) => m.senderId == entry.studentId && m.recipientId == teacherId && m.readAt == null).length;
      return (entry: entry, lastMessage: lastMessage, unreadCount: unreadCount);
    }).toList()
      ..sort((a, b) {
        if (a.lastMessage == null && b.lastMessage == null) return 0;
        if (a.lastMessage == null) return 1;
        if (b.lastMessage == null) return -1;
        return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: conversations.isEmpty
          ? const Center(child: Text('Bu sınıfa henüz öğrenci katılmadı.', style: TextStyle(color: AppColors.muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final entry = conversation.entry;
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(
                      '/class/$classId/messages/${entry.studentId}',
                      extra: entry.profile?.fullName ?? 'Öğrenci',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.profile?.fullName ?? 'İsimsiz',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  conversation.lastMessage?.content ?? 'Henüz mesaj yok',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
