import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/assignment.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';

/// Ödevler — assignments, announcements and tasks sent by the teacher to
/// this student's class.
class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return RefreshIndicator(
      onRefresh: app.refresh,
      child: app.assignments.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('Henüz ödev, duyuru veya görev yok.', style: TextStyle(color: cc.text2))),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: app.assignments.length,
              itemBuilder: (context, i) => _AssignmentCard(assignment: app.assignments[i], app: app),
            ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final AppState app;
  const _AssignmentCard({required this.assignment, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final a = assignment;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cc.s1, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(999)),
                child: Text(asgTypeLabel[a.type] ?? a.type, style: TextStyle(color: cc.text2, fontSize: 11)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Sesli Oku',
                onPressed: () => app.speak('${a.title}. ${a.body}'),
                icon: const Text('🔊', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cc.text1)),
          if (a.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(a.body, style: TextStyle(color: cc.text2)),
          ],
          if (a.dueDate != null) ...[
            const SizedBox(height: 6),
            Text('📅 Son tarih: ${a.dueDate}', style: TextStyle(color: cc.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
          if (a.fileUrl != null && a.fileName != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _openFile(context, a.fileUrl!),
              child: Text('📎 ${a.fileName}', overflow: TextOverflow.ellipsis),
            ),
          ],
          const SizedBox(height: 6),
          Text(trDateTime(a.createdAt), style: TextStyle(color: cc.text2, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'Dosya açılamadı');
  }
}
