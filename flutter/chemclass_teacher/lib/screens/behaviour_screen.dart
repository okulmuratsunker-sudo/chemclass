import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/class_chips.dart';
import '../widgets/modals.dart';
import '../widgets/score_action_button.dart';
import '../widgets/student_avatar.dart';

/// Davranış - mirrors `index.html`'s `#beh` section: class filter, search,
/// optional note, the custom score buttons editor and per-student scoring.
class BehaviourScreen extends StatefulWidget {
  const BehaviourScreen({super.key});

  @override
  State<BehaviourScreen> createState() => _BehaviourScreenState();
}

class _BehaviourScreenState extends State<BehaviourScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final query = trLower(_searchCtrl.text.trim());
    final all = app.getByClass(app.selectedBehClass.isEmpty ? null : app.selectedBehClass);
    final ss = query.isEmpty
        ? all
        : all.where((s) => trLower(s.name).contains(query) || s.no.contains(query)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedBehClass,
              allowAll: true,
              onSelected: (c) {
                app.selectedBehClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: '🔍 Öğrenci ara...'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(hintText: 'İsteğe bağlı not...')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('⚙️ Özel Puan Butonları',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cc.text1)),
                      ),
                      OutlinedButton(onPressed: () => showCustomButtonsDialog(context, app), child: const Text('Düzenle')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (app.data.customBtns.isEmpty)
                    Text('Henüz özel buton yok. Düzenle\'ye bas.', style: TextStyle(color: cc.text2, fontSize: 12))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final b in app.data.customBtns) _CustomBtnTag(button: b)],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (ss.isEmpty)
              Text('Öğrenci yok.', style: TextStyle(color: cc.text2))
            else
              for (final s in ss) _BehRow(student: s, app: app, noteCtrl: _noteCtrl),
          ],
        ),
      ),
    );
  }
}

class _BehRow extends StatelessWidget {
  final Student student;
  final AppState app;
  final TextEditingController noteCtrl;
  const _BehRow({required this.student, required this.app, required this.noteCtrl});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(student: student),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                    Text('${student.className} • No: ${student.no.isEmpty ? '-' : student.no}',
                        style: TextStyle(color: cc.text2, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ScoreText(score: student.score),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showHistoryDialog(context, student),
                    icon: const Text('📋'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ScoreActionButton(label: '−1', color: cc.red, onTap: () => _change(-1, 'Uyarı')),
              ScoreActionButton(label: '+1', color: cc.green, onTap: () => _change(1, 'Katılım')),
              ScoreActionButton(label: '+2', color: cc.green, onTap: () => _change(2, 'Doğru cevap')),
              ScoreActionButton(label: '+3', color: cc.green, onTap: () => _change(3, 'Grup liderliği')),
              for (final b in app.data.customBtns)
                ScoreActionButton(
                  label: '${b.val > 0 ? '+' : ''}${b.val} ${b.label}',
                  color: cc.gold,
                  onTap: () => _change(b.val, b.label),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: cc.border, height: 1),
        ],
      ),
    );
  }

  void _change(int delta, String label) {
    app.changeScore(student.id, delta, label: label, note: noteCtrl.text);
    noteCtrl.clear();
  }
}

class _CustomBtnTag extends StatelessWidget {
  final CustomButton button;
  const _CustomBtnTag({required this.button});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cc.gold.withValues(alpha: 0.12),
        border: Border.all(color: cc.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${button.val > 0 ? '+' : ''}${button.val} ${button.label}',
        style: TextStyle(color: cc.gold, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
