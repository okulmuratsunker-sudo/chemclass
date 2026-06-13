import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson_session.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/formatters.dart';
import 'dialogs/session_form_dialog.dart';

/// Dersler page, mirroring `ders-takip.html`'s `renderSessions()`.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;
    final fs = app.filteredSessions;
    final total = fs.fold<double>(0, (a, s) => a + s.amount);
    final unpaid = fs.where((s) => !s.paid).fold<double>(0, (a, s) => a + s.amount);

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
                    Text('Dersler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dt.text1)),
                    const SizedBox(width: 8),
                    _Badge(text: '${fs.length}'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => showSessionFormDialog(context, app),
                child: const Text('+ Ders Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterBar(app: app),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Chip(label: 'Toplam', value: fmt(total), color: dt.text1),
              _Chip(label: 'Ödenmedi', value: fmt(unpaid), color: dt.red),
            ],
          ),
          const SizedBox(height: 12),
          if (fs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Bu filtreye uygun ders bulunamadı', style: TextStyle(color: dt.text3))),
            )
          else
            for (final s in fs) _SessionCard(session: s),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AppState app;
  const _FilterBar({required this.app});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: app.filterStudentId,
          decoration: const InputDecoration(labelText: 'Öğrenci'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Tüm öğrenciler')),
            ...app.students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
          ],
          onChanged: (val) => app.setFilter(studentId: val ?? ''),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterButton(
              label: app.filterMonth.isEmpty || app.filterMonth == thisMonth()
                  ? '📅 Ay Seç'
                  : '📅 ${monthLabel(app.filterMonth)}',
              active: false,
              onTap: () => _pickMonth(context),
            ),
            _FilterButton(
              label: 'Tüm Zamanlar',
              active: app.filterMonth == '',
              onTap: () => app.setFilter(month: ''),
            ),
            _FilterButton(
              label: 'Bu Ay',
              active: app.filterMonth == thisMonth(),
              onTap: () => app.setFilter(month: thisMonth()),
            ),
            Container(width: 1, height: 24, color: dt.border2),
            _FilterButton(
              label: 'Tümü',
              active: app.filterPaid == '',
              onTap: () => app.setFilter(paid: ''),
            ),
            _FilterButton(
              label: 'Ödenmedi',
              active: app.filterPaid == 'false',
              onTap: () => app.setFilter(paid: 'false'),
            ),
            _FilterButton(
              label: 'Ödendi',
              active: app.filterPaid == 'true',
              onTap: () => app.setFilter(paid: 'true'),
            ),
            TextButton(
              onPressed: app.resetFilters,
              style: TextButton.styleFrom(foregroundColor: dt.text3),
              child: const Text('↺ Sıfırla'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final base = app.filterMonth.isNotEmpty
        ? DateTime.tryParse('${app.filterMonth}-01') ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Ay seçin',
    );
    if (picked != null) {
      app.setFilter(month: thisMonth(picked));
    }
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? dt.green.withValues(alpha: 0.1) : dt.s2,
        foregroundColor: active ? dt.green : dt.text2,
        side: BorderSide(color: active ? dt.green.withValues(alpha: 0.3) : dt.border2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        minimumSize: Size.zero,
      ),
      child: Text(label),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dt.s2,
        border: Border.all(color: dt.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: dt.text3),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(text: value, style: TextStyle(fontFamily: 'monospace', color: color)),
          ],
        ),
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

class _SessionCard extends StatelessWidget {
  final LessonSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final dt = Theme.of(context).dt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.studentName(session.studentId),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: dt.text1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(fmtDate(session.date), style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.text2)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(fmtDur(session.duration), style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.text2)),
                const SizedBox(width: 12),
                Text(fmt(session.amount), style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: dt.text1)),
              ],
            ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(session.notes!, style: TextStyle(fontSize: 12, color: dt.text3), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _PaidBadge(paid: session.paid, onTap: () => app.togglePaid(session.id, session.paid)),
                const Spacer(),
                IconButton(
                  tooltip: 'Düzenle',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showSessionFormDialog(context, app, session: session),
                  icon: const Text('✏️'),
                ),
                IconButton(
                  tooltip: 'Sil',
                  visualDensity: VisualDensity.compact,
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
    final ok = await confirmDialog(context, 'Dersi Sil', 'Bu ders silinsin mi?', confirmLabel: 'Sil');
    if (ok) await app.deleteSession(session.id);
  }
}

class _PaidBadge extends StatelessWidget {
  final bool paid;
  final VoidCallback onTap;
  const _PaidBadge({required this.paid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    final color = paid ? dt.green : dt.red;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          paid ? '✓ Ödendi' : '✕ Bekliyor',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
