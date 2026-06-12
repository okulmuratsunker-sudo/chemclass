import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';

/// Mesajlar - new feature with no direct `index.html` equivalent: teacher
/// chats with a single student, a whole class, or broadcasts to everyone,
/// plus a searchable history and a 1:1 conversation view.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      app.loadTeacherMessages();
      app.setupTeacherRealtime();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    if (app.convStudentId != null) {
      return const _ConversationView();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('💬 Mesajlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 10),
            if (app.sbUser == null)
              Text('Mesajlaşmak için önce bulut hesabına giriş yapmalısınız.', style: TextStyle(color: cc.text2))
            else ...[
              Text('Kime gönderilsin?', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScopeChip(label: '👤 Öğrenci', scope: 'student', app: app),
                  _ScopeChip(label: '🏫 Sınıf', scope: 'class', app: app),
                  _ScopeChip(label: '📢 Herkes', scope: 'all', app: app),
                ],
              ),
              const SizedBox(height: 10),
              if (app.selectedMessageScope == 'student' || app.selectedMessageScope == 'class') ...[
                Text('Sınıf', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 6),
                ClassChips(
                  classes: app.data.classes,
                  selected: app.selectedMessageClass,
                  allowAll: app.selectedMessageScope == 'student',
                  onSelected: (c) {
                    app.selectedMessageClass = c;
                    if (app.selectedMessageScope == 'student') app.selectedMessageStudentId = null;
                    app.notify();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (app.selectedMessageScope == 'student') ...[
                Text('Öğrenci', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: app.messageStudentOptions.any((s) => s.id == app.selectedMessageStudentId)
                      ? app.selectedMessageStudentId
                      : null,
                  items: [
                    for (final s in app.messageStudentOptions)
                      DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.className})')),
                  ],
                  hint: const Text('Öğrenci seçin'),
                  onChanged: (v) {
                    app.selectedMessageStudentId = v;
                    app.notify();
                  },
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(hintText: 'Mesajınızı yazın...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : () => _send(app),
                    child: const Text('Gönder'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: cc.border),
              const SizedBox(height: 10),
              Text('Mesaj Geçmişi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cc.text1)),
              const SizedBox(height: 6),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: '🔍 Mesajlarda ara...'),
                onChanged: app.setMsgSearchQuery,
              ),
              const SizedBox(height: 10),
              if (app.filteredMessageHistory.isEmpty)
                Text('Henüz mesaj yok.', style: TextStyle(color: cc.text2))
              else
                for (final row in app.filteredMessageHistory) _MessageHistoryRow(row: row, app: app),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _send(AppState app) async {
    setState(() => _sending = true);
    final err = await app.sendTeacherMessage(_msgCtrl.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      showSnack(context, err);
    } else {
      _msgCtrl.clear();
    }
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final String scope;
  final AppState app;
  const _ScopeChip({required this.label, required this.scope, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final isSel = app.selectedMessageScope == scope;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) {
        app.selectedMessageScope = scope;
        app.notify();
      },
      selectedColor: cc.green,
      labelStyle: TextStyle(
        color: isSel ? const Color(0xFF071018) : cc.text1,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: cc.s2,
      side: BorderSide(color: cc.border),
    );
  }
}

class _MessageHistoryRow extends StatelessWidget {
  final MsgHistoryRow row;
  final AppState app;
  const _MessageHistoryRow({required this.row, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final m = row.message;
    return InkWell(
      onTap: m.studentId == null ? null : () => app.openConversation(m.studentId!),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(row.out ? '➡️' : '⬅️', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(child: Text(row.who, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1))),
                Text(trDateTime(m.createdAt), style: TextStyle(color: cc.text2, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(m.body, style: TextStyle(color: cc.text2)),
          ],
        ),
      ),
    );
  }
}

/// 1:1 conversation with a student, mirroring `openConversation()` /
/// `sendConversationReply()`.
class _ConversationView extends StatefulWidget {
  const _ConversationView();

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final messages = app.conversationMessages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(onPressed: app.closeConversation, icon: const Icon(Icons.arrow_back)),
                Expanded(
                  child: Text(app.conversationTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (messages.isEmpty)
              Text('Henüz mesaj yok.', style: TextStyle(color: cc.text2))
            else
              for (final m in messages) _ConversationBubble(message: m),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(hintText: 'Yanıt yazın...'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : () => _send(app),
                  child: const Text('Gönder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(AppState app) async {
    setState(() => _sending = true);
    final err = await app.sendConversationReply(_replyCtrl.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      showSnack(context, err);
    } else {
      _replyCtrl.clear();
    }
  }
}

class _ConversationBubble extends StatelessWidget {
  final ChatMessage message;
  const _ConversationBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final out = message.sender == 'teacher';
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
            Text(message.body, style: TextStyle(color: cc.text1)),
            const SizedBox(height: 2),
            Text(trTime(message.createdAt), style: TextStyle(color: cc.text2, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
