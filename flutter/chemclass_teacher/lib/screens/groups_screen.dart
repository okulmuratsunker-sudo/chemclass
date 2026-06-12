import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';
import '../widgets/student_avatar.dart';

/// Gruplar - mirrors `index.html`'s `#groups` section: class filter, group
/// mode (count/size) + value, group generation, and per-group score editing.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late final TextEditingController _valCtrl;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _valCtrl = TextEditingController(text: '${app.groupVal}');
  }

  @override
  void dispose() {
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedGroupClass,
              onSelected: (c) {
                app.selectedGroupClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: app.groupMode,
                    items: const [
                      DropdownMenuItem(value: 'count', child: Text('Grup sayısı')),
                      DropdownMenuItem(value: 'size', child: Text('Gruptaki kişi sayısı')),
                    ],
                    onChanged: (v) {
                      app.groupMode = v ?? app.groupMode;
                      app.notify();
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _valCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => app.groupVal = int.tryParse(v) ?? app.groupVal,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _make(context, app),
                  child: const Text('👥 Grupları Oluştur'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Grup puanları yeniden oluşturulana kadar korunur.', style: TextStyle(color: cc.text2, fontSize: 12)),
            const SizedBox(height: 10),
            if (app.groups.isEmpty)
              Text('Henüz grup oluşturulmadı.', style: TextStyle(color: cc.text2))
            else
              for (var i = 0; i < app.groups.length; i++) _GroupRow(index: i, app: app),
          ],
        ),
      ),
    );
  }

  void _make(BuildContext context, AppState app) {
    final err = app.makeGroups(app.selectedGroupClass);
    if (err != null) showSnack(context, err);
  }
}

class _GroupRow extends StatelessWidget {
  final int index;
  final AppState app;
  const _GroupRow({required this.index, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final g = app.groups[index];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: ValueKey(g.id),
                  initialValue: g.name,
                  style: TextStyle(color: cc.text1),
                  onChanged: (v) => app.renameGroup(index, v),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in g.members)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cc.s1,
                          border: Border.all(color: cc.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(m.name, style: TextStyle(color: cc.text2, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              OutlinedButton(
                onPressed: () => app.incrementGroupScore(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cc.green,
                  side: BorderSide(color: cc.green.withValues(alpha: 0.4)),
                  backgroundColor: cc.green.withValues(alpha: 0.12),
                  minimumSize: const Size(40, 36),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('+', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              ScoreText(score: g.score),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => app.decrementGroupScore(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cc.red,
                  side: BorderSide(color: cc.red.withValues(alpha: 0.4)),
                  backgroundColor: cc.red.withValues(alpha: 0.12),
                  minimumSize: const Size(40, 36),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('−', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
