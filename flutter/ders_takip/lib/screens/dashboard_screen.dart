import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson_session.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import 'dialogs/session_form_dialog.dart';
import 'dialogs/student_form_dialog.dart';
import 'student_detail_screen.dart';

/// Özet (dashboard) page, mirroring `ders-takip.html`'s `renderDashboard()`.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;

    final total = app.totalIncome;
    final unpaidList = app.unpaidSessions;
    final unpaid = app.unpaidTotal;
    final dur = app.totalDuration;

    return RefreshIndicator(
      onRefresh: () => app.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              StatCard(
                icon: '👤',
                label: 'Öğrenci',
                value: '${app.students.length}',
                sub: 'kayıtlı öğrenci',
                color: dt.blue,
              ),
              StatCard(
                icon: '💰',
                label: 'Toplam Gelir',
                value: fmtS(total),
                sub: '${app.sessions.length} ders',
                color: dt.green,
              ),
              StatCard(
                icon: '⚠️',
                label: 'Ödenmedi',
                value: fmtS(unpaid),
                sub: '${unpaidList.length} ders bekliyor',
                color: dt.red,
              ),
              StatCard(
                icon: '📅',
                label: 'Toplam Ders',
                value: '${app.sessions.length}',
                sub: 'toplam ${fmtDur(dur)}',
                color: dt.yellow,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Son Dersler',
            actionLabel: '+ Ders Ekle',
            onAction: () => showSessionFormDialog(context, app),
            child: app.sessions.isEmpty
                ? _EmptyHint(text: 'Henüz ders yok')
                : Column(
                    children: app.recentSessions.map((s) => _RecentSessionItem(session: s)).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Öğrenciler',
            actionLabel: '+ Ekle',
            onAction: () => showStudentFormDialog(context, app),
            child: app.students.isEmpty
                ? _EmptyHint(text: 'Henüz öğrenci yok')
                : Column(
                    children: app.students.map((s) => _StudentListItem(student: s)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dt.text1)),
                ),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text, style: TextStyle(color: dt.text3, fontSize: 13))),
    );
  }
}

class _RecentSessionItem extends StatelessWidget {
  final LessonSession session;
  const _RecentSessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final dt = Theme.of(context).dt;
    final notes = session.notes;
    var subtitle = '${fmtDate(session.date)} · ${fmtDur(session.duration)}';
    if (notes != null && notes.isNotEmpty) {
      subtitle += ' · ${notes.length > 30 ? notes.substring(0, 30) : notes}';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dt.s2,
        border: Border.all(color: dt.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(session.paid ? '✅' : '⏳', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.studentName(session.studentId),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dt.text1),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: dt.text3)),
              ],
            ),
          ),
          Text(fmt(session.amount), style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: dt.text1)),
        ],
      ),
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final Student student;
  const _StudentListItem({required this.student});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final dt = Theme.of(context).dt;
    final stSessions = app.sessionsFor(student.id);
    final unpaid = app.unpaidFor(student.id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: student.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dt.s2,
          border: Border.all(color: dt.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('👤', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dt.text1),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${fmt(student.hourlyRate)}/saat · ${stSessions.length} ders',
                    style: TextStyle(fontSize: 11, color: dt.text3),
                  ),
                ],
              ),
            ),
            Text(
              unpaid > 0 ? fmt(unpaid) : '✓',
              style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: unpaid > 0 ? dt.red : dt.green),
            ),
            const SizedBox(width: 4),
            Text('›', style: TextStyle(color: dt.text3, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
