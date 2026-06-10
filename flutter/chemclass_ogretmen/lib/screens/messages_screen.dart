import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/app_data.dart';
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
  String? _selectedClass; // null = "Tümü" (genel bakış)
  String? _selectedStudentId; // null = sınıf geneli duyuru

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

  List<TeacherMessage> _filter(List<TeacherMessage> messages) {
    if (_selectedClass == null) return messages;
    if (_selectedStudentId == null) {
      return messages
          .where((m) => m.className == _selectedClass && m.studentId == null)
          .toList();
    }
    return messages.where((m) => m.studentId == _selectedStudentId).toList();
  }

  String _hintText(AppData appData) {
    if (_selectedClass == null) return 'Mesaj göndermek için bir sınıf seçin';
    if (_selectedStudentId == null) return '$_selectedClass sınıfına duyuru yaz...';
    final student = appData.findStudent(_selectedStudentId!);
    return student != null ? '${student.name} kişisine mesaj yaz...' : 'Mesaj yaz...';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_messagesProvider);
    final appData = ref.watch(appDataProvider);
    final canSend = _selectedClass != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Class selector
          Container(
            color: kSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _ConvChip(
                    label: '📢 Tümü',
                    selected: _selectedClass == null,
                    onTap: () => setState(() {
                      _selectedClass = null;
                      _selectedStudentId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ...appData.classes.map((cls) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ConvChip(
                      label: cls,
                      selected: _selectedClass == cls,
                      onTap: () => setState(() {
                        _selectedClass = cls;
                        _selectedStudentId = null;
                      }),
                    ),
                  )),
                ],
              ),
            ),
          ),
          // Student selector (within the selected class)
          if (_selectedClass != null)
            Container(
              color: kSurface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _ConvChip(
                      label: '📢 Sınıfa Duyuru',
                      selected: _selectedStudentId == null,
                      compact: true,
                      onTap: () => setState(() => _selectedStudentId = null),
                    ),
                    const SizedBox(width: 8),
                    ...appData.studentsOf(_selectedClass!).map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ConvChip(
                        label: '👤 ${s.name}',
                        selected: _selectedStudentId == s.id,
                        compact: true,
                        onTap: () => setState(() => _selectedStudentId = s.id),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          Container(height: 1, color: kSurface2),
          // Messages
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
              data: (messages) {
                final filtered = _filter(messages);
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
                  itemBuilder: (_, i) => _MessageBubble(
                    message: filtered[i],
                    appData: appData,
                    showRecipient: _selectedClass == null,
                  ),
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
                    enabled: canSend,
                    style: TextStyle(color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: _hintText(appData),
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
                  onTap: canSend ? _sendMessage : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: canSend ? kAccent : kSurface2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: canSend ? kBg : kTextSecondary, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_selectedClass == null) return;
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    _msgCtrl.clear();
    await SupabaseService.sendMessage(
      studentId: _selectedStudentId,
      className: _selectedClass!,
      body: body,
    );
    ref.invalidate(_messagesProvider);
  }
}

class _ConvChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  const _ConvChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 6 : 7),
        decoration: BoxDecoration(
          color: selected ? kAccent : kSurface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? kBg : kTextSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          fontSize: compact ? 12 : 13,
        )),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TeacherMessage message;
  final AppData appData;
  final bool showRecipient;
  const _MessageBubble({
    required this.message,
    required this.appData,
    this.showRecipient = false,
  });

  String? get _recipientLabel {
    if (!showRecipient) return null;
    if (message.studentId != null) {
      final s = appData.findStudent(message.studentId!);
      if (s != null) return '👤 ${s.name}';
      return message.className != null && message.className!.isNotEmpty
          ? message.className
          : null;
    }
    if (message.className != null && message.className!.isNotEmpty) {
      return '📢 ${message.className}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = message.isFromTeacher;
    final recipient = _recipientLabel;
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
                  if (recipient != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        recipient,
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
