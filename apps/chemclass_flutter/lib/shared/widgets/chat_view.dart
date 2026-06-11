import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/messages_repository.dart';

/// 1:1 chat thread between [currentUserId] and [peerId] within a class.
/// Used both by the teacher (per-student thread) and the student (thread
/// with their teacher) apps.
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.classId, required this.peerId, required this.currentUserId});

  final String classId;
  final String peerId;
  final String currentUserId;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ClassMessagesController _controller;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = ClassMessagesController(classId: widget.classId);
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    _markRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markRead() async {
    final unreadIds = _controller
        .threadWith(widget.currentUserId, widget.peerId)
        .where((m) => m.senderId == widget.peerId && m.recipientId == widget.currentUserId && m.readAt == null)
        .map((m) => m.id)
        .toList();
    await markMessagesRead(unreadIds);
  }

  Future<void> _onSend() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    _textController.clear();
    final error = await sendMessage(
      classId: widget.classId,
      senderId: widget.currentUserId,
      recipientId: widget.peerId,
      content: content,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) _textController.text = content;
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final thread = _controller.threadWith(widget.currentUserId, widget.peerId);

    return Column(
      children: [
        Expanded(
          child: thread.isEmpty
              ? const Center(
                  child: Text('Henüz mesaj yok.', style: TextStyle(color: AppColors.muted)),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: thread.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = thread[index];
                    final isMine = message.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: isMine ? null : Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMine ? AppColors.primaryText : AppColors.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yaz...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _onSend,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
