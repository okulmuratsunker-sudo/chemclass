import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/class_chips.dart';
import '../widgets/modals.dart';
import '../widgets/student_avatar.dart';

/// Liderlik Tablosu - mirrors `index.html`'s `#board` section: class filter
/// (with "Tüm"), search, ranked list with relative score bars, and an
/// optional class-comparison view.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _searchCtrl = TextEditingController();
  bool _compareVisible = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final cls = app.selectedBoardClass;
    final query = trLower(_searchCtrl.text.trim());

    var ss = List<Student>.from(app.getByClass(cls.isEmpty ? null : cls))
      ..sort((a, b) => b.score.compareTo(a.score));
    if (query.isNotEmpty) {
      ss = ss.where((s) => trLower(s.name).contains(query) || s.no.contains(query)).toList();
    }
    final mx = ss.fold<int>(1, (m, s) => max(m, s.score.abs()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassChips(
              classes: app.data.classes,
              selected: cls,
              allowAll: true,
              onSelected: (c) {
                app.selectedBoardClass = c;
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
            OutlinedButton(
              onPressed: () => setState(() => _compareVisible = !_compareVisible),
              child: const Text('📊 Sınıf Karşılaştır'),
            ),
            const SizedBox(height: 10),
            if (ss.isEmpty)
              Text('Öğrenci yok.', style: TextStyle(color: cc.text2))
            else
              for (var i = 0; i < ss.length; i++) _BoardRow(rank: i + 1, student: ss[i], maxScore: mx),
            if (_compareVisible) ...[
              const SizedBox(height: 14),
              Text('📊 Sınıf Karşılaştırması',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cc.text1)),
              const SizedBox(height: 6),
              _CompareList(app: app),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  final int rank;
  final Student student;
  final int maxScore;
  const _BoardRow({required this.rank, required this.student, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final barValue = max(0.04, student.score.abs() / maxScore);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 34, child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1))),
          StudentAvatar(student: student),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barValue,
                    minHeight: 6,
                    backgroundColor: cc.s2,
                    color: student.score < 0 ? cc.red : cc.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(student.className, style: TextStyle(color: cc.text2, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => showHistoryDialog(context, student),
            icon: const Text('📋'),
          ),
          ScoreText(score: student.score),
        ],
      ),
    );
  }
}

class _CompareList extends StatelessWidget {
  final AppState app;
  const _CompareList({required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final classes = app.data.classes;
    if (classes.isEmpty) return Text('Sınıf yok.', style: TextStyle(color: cc.text2));

    final stats = classes.map((c) {
      final ss = app.data.students.where((s) => s.className == c).toList();
      final total = ss.fold<int>(0, (a, s) => a + s.score);
      final avg = ss.isEmpty ? 0.0 : (total / ss.length * 10).round() / 10;
      return (c: c, total: total, avg: avg, n: ss.length);
    }).toList();

    final maxTotal = stats.fold<int>(1, (m, x) => max(m, x.total.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(stats[i].c, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                    const SizedBox(width: 6),
                    Text('${stats[i].n} öğrenci • Ort: ${stats[i].avg > 0 ? '+' : ''}${_fmtNum(stats[i].avg)}',
                        style: TextStyle(color: cc.text2, fontSize: 12)),
                    const Spacer(),
                    Text('${stats[i].total > 0 ? '+' : ''}${stats[i].total}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(width: 56, child: Text('Toplam', style: TextStyle(color: cc.text2, fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: max(0.04, stats[i].total.abs() / maxTotal),
                          minHeight: 8,
                          backgroundColor: cc.s2,
                          color: compareColors[i % compareColors.length],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
