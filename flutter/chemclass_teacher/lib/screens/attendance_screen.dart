import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';
import '../widgets/modals.dart';
import '../widgets/student_avatar.dart';

/// Yoklama - mirrors `index.html`'s `#attend` section: class/date pickers,
/// mark-all buttons, save, stats, and per-student P/A/E toggles.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final cls = app.selectedAttClass;
    final students = cls.isEmpty ? <Student>[] : app.getByClass(cls);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassChips(
              classes: app.data.classes,
              selected: cls,
              onSelected: (c) {
                app.selectedAttClass = c;
                app.ensureAttState(c);
                app.notify();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Tarih:', style: TextStyle(color: cc.text2)),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _pickDate(context, app),
                  child: Text(trDate(DateTime.parse(app.attDate))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: cls.isEmpty ? null : () => app.attMarkAll(cls, 'P'),
                  child: const Text('✓ Hepsini Geldi'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
                  onPressed: cls.isEmpty ? null : () => app.attMarkAll(cls, 'A'),
                  child: const Text('✗ Hepsini Gelmedi'),
                ),
                OutlinedButton(onPressed: () => _save(context, app), child: const Text('💾 Yoklamayı Kaydet')),
                OutlinedButton(
                  onPressed: () => cls.isEmpty ? showSnack(context, 'Sınıf seçin') : showAttStatsDialog(context, app, cls),
                  child: const Text('📊 İstatistik'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (cls.isEmpty)
              Text('Önce sınıf seçin.', style: TextStyle(color: cc.text2))
            else if (students.isEmpty)
              Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: cc.text2))
            else ...[
              for (final s in students) _AttRow(student: s, app: app),
              const SizedBox(height: 10),
              _buildCountsBox(app, cc, cls),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, AppState app) async {
    final current = DateTime.tryParse(app.attDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      app.setAttDate(todayStr(picked));
      app.ensureAttState(app.selectedAttClass);
    }
  }

  void _save(BuildContext context, AppState app) {
    final err = app.saveAttendance(app.selectedAttClass);
    showSnack(context, err ?? 'Yoklama kaydedildi ✓');
  }

  Widget _buildCountsBox(AppState app, AppColors cc, String cls) {
    final counts = app.attCounts(cls);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountChip(label: '✓ Geldi: ${counts['P'] ?? 0}', color: cc.green),
        _CountChip(label: '✗ Gelmedi: ${counts['A'] ?? 0}', color: cc.red),
        _CountChip(label: '⚡ İzinli: ${counts['E'] ?? 0}', color: cc.gold),
        _CountChip(label: '? İşaretlenmedi: ${counts['x'] ?? 0}', color: cc.text2),
      ],
    );
  }
}

class _AttRow extends StatelessWidget {
  final Student student;
  final AppState app;
  const _AttRow({required this.student, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final st = app.attState[student.id] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          StudentAvatar(student: student),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                Text('No: ${student.no.isEmpty ? '-' : student.no}', style: TextStyle(color: cc.text2, fontSize: 12)),
              ],
            ),
          ),
          _AttButton(label: '✓', active: st == 'P', color: cc.green, onTap: () => app.setAtt(student.id, 'P')),
          const SizedBox(width: 6),
          _AttButton(label: '✗', active: st == 'A', color: cc.red, onTap: () => app.setAtt(student.id, 'A')),
          const SizedBox(width: 6),
          _AttButton(label: '⚡', active: st == 'E', color: cc.gold, onTap: () => app.setAtt(student.id, 'E')),
        ],
      ),
    );
  }
}

class _AttButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _AttButton({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? color.withValues(alpha: 0.18) : cc.s2,
        foregroundColor: active ? color : cc.text2,
        side: BorderSide(color: active ? color.withValues(alpha: 0.5) : cc.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
