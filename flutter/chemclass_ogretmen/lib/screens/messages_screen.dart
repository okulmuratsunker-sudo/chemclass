import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/message.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

final _messagesProvider = FutureProvider<List<TeacherMessage>>((ref) async {
  return SupabaseService.loadMessages();
});

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  RealtimeChannel? _channel;
  String? _selectedConversation; // null = all
  final _scrollCtrl = ScrollController();
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _channel = SupabaseService.subscribeMessages(() {
      if (mounted) ref.invalidate(_messagesProvider);
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_messagesProvider);
    final appData = ref.watch(appDataProvider);

    return Column(
      children: [
        // Conversation selector
        Container(
          color: kSurface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _ConvChip(
                  label: '📢 Tümü',
                  selected: _selectedConversation == null,
                  onTap: () => setState(() => _selectedConversation = null),
                ),
                const SizedBox(width: 8),
                ...appData.classes.map((cls) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ConvChip(
                    label: cls,
                    selected: _selectedConversation == cls,
                    onTap: () => setState(() => _selectedConversation = cls),
                  ),
                )),
              ],
            ),
          ),
        ),
        // Messages
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
            data: (messages) {
              final filtered = _selectedConversation == null
                  ? messages
                  : messages.where((m) => m.className == _selectedConversation).toList();
              if (filtered.isEmpty) {
                return Center(child: Text('Henüz mesaj yok.', style: TextStyle(color: kTextSecondary)));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.animateTo(
                    _scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _MessageBubble(message: filtered[i]),
              );
            },
          ),
        ),
        // Compose
        Container(
          color: kSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: TextStyle(color: kTextPrimary),
                  decoration: InputDecoration(
                    hintText: _selectedConversation != null
                        ? '$_selectedConversation sınıfına mesaj...'
                        : 'Mesaj yaz...',
                    hintStyle: TextStyle(color: kTextSecondary),
                    filled: true,
                    fillColor: kSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send, color: kBg, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    _msgCtrl.clear();
    await SupabaseService.sendMessage(
      studentId: null,
      className: _selectedConversation ?? '',
      body: body,
    );
    ref.invalidate(_messagesProvider);
  }
}

class _ConvChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ConvChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAccent : kSurface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? kBg : kTextSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TeacherMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isTeacher = message.isFromTeacher;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isTeacher ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isTeacher) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: kAccent.withOpacity(0.2),
              child: Text(
                (message.senderName ?? 'Ö').substring(0, 1).toUpperCase(),
                style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isTeacher ? kAccent : kSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isTeacher ? 16 : 4),
                  bottomRight: Radius.circular(isTeacher ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isTeacher && message.senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName!,
                        style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (message.className != null && message.className!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.className!,
                        style: TextStyle(
                          color: isTeacher ? kBg.withOpacity(0.7) : kTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isTeacher ? kBg : kTextPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      color: isTeacher ? kBg.withOpacity(0.6) : kTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
