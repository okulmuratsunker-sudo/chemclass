import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/lesson_session.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'receipt_screen.dart';

/// Student detail page, mirroring `ders-takip.html`'s `openStudentDetail()`
/// modal: lesson stats, full session history and PNG/receipt export actions.
class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _screenshotController = ScreenshotController();
  List<LessonSession>? _sessions;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final list = await app.fetchSessionsForStudent(widget.studentId, ascending: false);
    if (!mounted) return;
    setState(() => _sessions = list);
  }

  Future<void> _exportPng() async {
    final app = context.read<AppState>();
    app.toast('PNG oluşturuluyor...');
    try {
      final bytes = await _screenshotController.capture();
      if (bytes == null) throw Exception('capture failed');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ders-detay.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      app.toast('PNG indirildi');
    } catch (_) {
      app.toast('PNG oluşturulamadı');
    }
  }

  Future<void> _sendToParent() async {
    final app = context.read<AppState>();
    final matches = app.students.where((s) => s.id == widget.studentId);
    if (matches.isEmpty) return;
    setState(() => _sending = true);
    app.toast('Rapor hazırlanıyor...');
    final list = await app.fetchSessionsForStudent(widget.studentId, ascending: true);
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(student: matches.first, sessions: list)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;
    final matches = app.students.where((s) => s.id == widget.studentId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Öğrenci')),
        body: Center(child: Text('Öğrenci bulunamadı', style: TextStyle(color: dt.text3))),
      );
    }
    final st = matches.first;
    final sData = _sessions;

    final totalAmt = (sData ?? []).fold<double>(0, (a, s) => a + s.amount);
    final paidAmt = (sData ?? []).where((s) => s.paid).fold<double>(0, (a, s) => a + s.amount);
    final unpaidAmt = totalAmt - paidAmt;
    final totalDur = (sData ?? []).fold<double>(0, (a, s) => a + s.duration);

    return Scaffold(
      appBar: AppBar(title: Text('👤 ${st.name}')),
      body: sData == null
          ? const Center(child: CircularProgressIndicator())
          : Screenshot(
              controller: _screenshotController,
              child: Container(
                color: dt.bg,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _DStat(label: 'Toplam Ders', value: '${sData.length} ders', color: dt.blue),
                        _DStat(label: 'Toplam Süre', value: fmtDur(totalDur), color: dt.blue),
                        _DStat(label: 'Ödendi', value: fmt(paidAmt), color: dt.green),
                        _DStat(
                          label: 'Kalan Borç',
                          value: fmt(unpaidAmt),
                          color: unpaidAmt > 0 ? dt.red : dt.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (sData.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('Henüz ders kaydedilmemiş', style: TextStyle(color: dt.text3))),
                      )
                    else
                      for (final s in sData) _HistoryItem(session: s),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: sData == null ? null : _exportPng,
                  child: const Text('🖼 PNG İndir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendToParent,
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('📤 Veliye Gönder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dt.s2,
        border: Border.all(color: dt.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: dt.text3)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final LessonSession session;
  const _HistoryItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(fmtDate(session.date), style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.text2)),
                const SizedBox(width: 12),
                Text(fmtDur(session.duration), style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.text2)),
                const Spacer(),
                Text(fmt(session.amount), style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: dt.text1)),
              ],
            ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(session.notes!, style: TextStyle(fontSize: 12, color: dt.text3), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            _StaticPaidBadge(paid: session.paid),
          ],
        ),
      ),
    );
  }
}

class _StaticPaidBadge extends StatelessWidget {
  final bool paid;
  const _StaticPaidBadge({required this.paid});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    final color = paid ? dt.green : dt.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        paid ? '✓ Ödendi' : '⏳ Bekliyor',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
