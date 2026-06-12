import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';

/// Mesajlar — a single 1:1 chat thread with the class teacher (plus
/// class-wide / everyone announcements from the teacher shown inline).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int _lastCount = -1;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final err = await context.read<AppState>().sendMessage(_msgCtrl.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      showSnack(context, err);
    } else {
      _msgCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final messages = app.messages;

    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToBottom();
    }

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(child: Text('Henüz mesaj yok. Öğretmenine yazabilirsin.', style: TextStyle(color: cc.text2)))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _ConversationBubble(message: messages[i]),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: cc.border))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(hintText: 'Mesajınızı yazın...'),
                  onSubmitted: (_) => _sending ? null : _send(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: const Text('Gönder'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final ChatMessage message;
  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final out = message.sender == 'student';
    final isBroadcast = message.studentId == null;
    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: out ? cc.green.withValues(alpha: 0.18) : cc.s2,
          border: Border.all(color: out ? cc.green.withValues(alpha: 0.4) : cc.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!out && isBroadcast)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('📢 Öğretmen', style: TextStyle(color: cc.text2, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Text(message.body, style: TextStyle(color: cc.text1)),
            const SizedBox(height: 2),
            Text(trTime(message.createdAt), style: TextStyle(color: cc.text2, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
