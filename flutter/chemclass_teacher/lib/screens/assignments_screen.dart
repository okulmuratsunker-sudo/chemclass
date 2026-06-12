import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/assignment.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';
import 'dialogs/new_assignment_dialog.dart';

/// Ödevler / Duyurular - new feature with no direct `index.html` equivalent:
/// teacher sends assignments/announcements/tasks to a class (with optional
/// due date and file attachment) for the Öğrenci app to display.
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTeacherAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final list = app.filteredAssignments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('📚 Ödevler / Duyurular',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
                ),
                ElevatedButton(
                  onPressed: app.sbUser == null ? null : () => showNewAssignmentDialog(context, app),
                  child: const Text('+ Yeni'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedAssignmentFilterClass,
              allowAll: true,
              onSelected: (c) {
                app.selectedAssignmentFilterClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 10),
            if (app.sbUser == null)
              Text('Ödev/duyuru göndermek ve görmek için önce bulut hesabına giriş yapmalısınız.',
                  style: TextStyle(color: cc.text2))
            else if (list.isEmpty)
              Text('Henüz ödev/duyuru yok.', style: TextStyle(color: cc.text2))
            else
              for (final a in list) _AssignmentCard(assignment: a, app: app),
          ],
        ),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(asgTypeLabel[a.type] ?? a.type, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration:
                    BoxDecoration(color: cc.s1, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(999)),
                child: Text(a.className, style: TextStyle(color: cc.text2, fontSize: 12)),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _delete(context),
                icon: Icon(Icons.delete_outline, color: cc.red),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cc.text1)),
          if (a.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(a.body, style: TextStyle(color: cc.text2)),
          ],
          if (a.dueDate != null) ...[
            const SizedBox(height: 4),
            Text('📅 Son tarih: ${a.dueDate}', style: TextStyle(color: cc.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          if (a.fileUrl != null && a.fileName != null) ...[
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => _openFile(context),
              child: Text('📎 ${a.fileName}', overflow: TextOverflow.ellipsis),
            ),
          ],
          const SizedBox(height: 4),
          Text(trDateTime(a.createdAt), style: TextStyle(color: cc.text2, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(context, 'Sil', '"${assignment.title}" silinsin mi?');
    if (ok) await app.deleteAssignment(assignment.id);
  }

  Future<void> _openFile(BuildContext context) async {
    final url = assignment.fileUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'Dosya açılamadı');
  }
}
