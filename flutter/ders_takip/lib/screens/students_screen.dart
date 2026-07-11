import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/formatters.dart';
import 'dialogs/session_form_dialog.dart';
import 'dialogs/student_form_dialog.dart';
import 'student_detail_screen.dart';

/// Öğrenciler page, mirroring `ders-takip.html`'s `renderStudents()`.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? app.students
        : app.students.where((s) => s.name.toLowerCase().contains(query)).toList();

    return RefreshIndicator(
      onRefresh: () => app.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('Öğrenciler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dt.text1)),
                    const SizedBox(width: 8),
                    _Badge(text: '${app.students.length}'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => showStudentFormDialog(context, app),
                child: const Text('+ Öğrenci Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(hintText: '🔍 Öğrenci ara...'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (app.students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Henüz öğrenci eklenmemiş', style: TextStyle(color: dt.text3))),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Sonuç bulunamadı', style: TextStyle(color: dt.text3))),
            )
          else
            for (final st in filtered) _StudentCard(student: st),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: dt.s2,
        border: Border.all(color: dt.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dt.text3, fontFamily: 'monospace')),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final dt = Theme.of(context).dt;
    final count = app.sessionsFor(student.id).length;
    final unpaid = app.unpaidFor(student.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: dt.text1)),
            const SizedBox(height: 4),
            Text('${fmt(student.hourlyRate)} / saat',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: dt.green)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'TOPLAM DERS', value: '$count', color: dt.text1)),
                const SizedBox(width: 8),
                Expanded(child: _MiniStat(label: 'ÖDENMEDİ', value: fmtS(unpaid), color: unpaid > 0 ? dt.red : dt.green)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Detay / Veliye gönder',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: student.id)),
                  ),
                  icon: const Text('📋'),
                ),
                IconButton(
                  tooltip: 'Ders ekle',
                  onPressed: () => showSessionFormDialog(context, app, preStudentId: student.id),
                  icon: const Text('📅'),
                ),
                IconButton(
                  tooltip: 'Düzenle',
                  onPressed: () => showStudentFormDialog(context, app, student: student),
                  icon: const Text('✏️'),
                ),
                IconButton(
                  tooltip: 'Sil',
                  onPressed: () => _delete(context, app),
                  icon: Icon(Icons.delete_outline, color: dt.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, AppState app) async {
    final ok = await confirmDialog(
      context,
      'Öğrenciyi Sil',
      '${student.name} silinsin mi? Tüm dersleri de silinir!',
      confirmLabel: 'Sil',
    );
    if (ok) await app.deleteStudent(student.id);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: dt.s2, borderRadius: BorderRadius.circular(9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: dt.text3, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
