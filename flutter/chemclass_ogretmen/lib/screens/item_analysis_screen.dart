import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

class ItemAnalysisScreen extends ConsumerStatefulWidget {
  const ItemAnalysisScreen({super.key});

  @override
  ConsumerState<ItemAnalysisScreen> createState() => _ItemAnalysisScreenState();
}

class _ItemAnalysisScreenState extends ConsumerState<ItemAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _examTypes = {'yazili1': 'Yazılı 1', 'yazili2': 'Yazılı 2'};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text('Madde Analizi', style: TextStyle(color: kTextPrimary)),
        iconTheme: IconThemeData(color: kTextSecondary),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kAccent,
          labelColor: kAccent,
          unselectedLabelColor: kTextSecondary,
          tabs: const [Tab(text: '1. Dönem'), Tab(text: '2. Dönem')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [1, 2].map((sem) => _AnalysisTab(
          semester: sem,
          examTypes: _examTypes,
          ref: ref,
        )).toList(),
      ),
    );
  }
}

class _AnalysisTab extends ConsumerStatefulWidget {
  final int semester;
  final Map<String, String> examTypes;
  final WidgetRef ref;
  const _AnalysisTab({required this.semester, required this.examTypes, required this.ref});

  @override
  ConsumerState<_AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends ConsumerState<_AnalysisTab> {
  String _examType = 'yazili1';
  List<ExamQuestion>? _questions;
  Map<String, double>? _scores;
  bool _loading = false;
  List<ItemAnalysisResult>? _results;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final questions = await SupabaseService.loadExamQuestions(
        semester: widget.semester,
        examType: _examType,
      );
      Map<String, double> scores = {};
      if (questions.isNotEmpty) {
        scores = await SupabaseService.loadQuestionScores(questions.map((q) => q.id).toList());
      }
      setState(() {
        _questions = questions;
        _scores = scores;
        _results = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _runAnalysis() {
    if (_questions == null || _questions!.isEmpty) return;
    final data = ref.read(appDataProvider);
    // All students (from AppData) — use all classes
    final allStudents = data.students;
    if (allStudents.isEmpty) return;

    // Calculate total score per student for this exam
    final studentTotals = <String, double>{};
    for (final s in allStudents) {
      double total = 0;
      for (final q in _questions!) {
        total += _scores!['${q.id}_${s.id}'] ?? 0;
      }
      studentTotals[s.id] = total;
    }

    // Sort students by total
    final sorted = allStudents.toList()
      ..sort((a, b) => (studentTotals[b.id] ?? 0).compareTo(studentTotals[a.id] ?? 0));

    final n = sorted.length;
    final twentySeven = (n * 0.27).ceil();
    final upper = sorted.take(twentySeven).map((s) => s.id).toSet();
    final lower = sorted.skip(n - twentySeven).map((s) => s.id).toSet();

    final results = <ItemAnalysisResult>[];
    for (final q in _questions!) {
      // All scores for this question
      final allScores = allStudents.map((s) => _scores!['${q.id}_${s.id}'] ?? 0.0).toList();
      final avgScore = allScores.isEmpty ? 0.0 : allScores.reduce((a, b) => a + b) / allScores.length;
      final p = q.maxPoints > 0 ? avgScore / q.maxPoints : 0.0;

      // Upper and lower group averages
      double upperAvg = 0, lowerAvg = 0;
      if (upper.isNotEmpty) {
        upperAvg = upper.map((id) => _scores!['${q.id}_$id'] ?? 0.0).reduce((a, b) => a + b) / upper.length;
      }
      if (lower.isNotEmpty) {
        lowerAvg = lower.map((id) => _scores!['${q.id}_$id'] ?? 0.0).reduce((a, b) => a + b) / lower.length;
      }
      final d = q.maxPoints > 0 ? (upperAvg - lowerAvg) / q.maxPoints : 0.0;

      results.add(ItemAnalysisResult(
        question: q,
        difficulty: p.clamp(0, 1),
        discrimination: d.clamp(-1, 1),
        classAvg: avgScore,
      ));
    }

    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Exam type selector + actions
        Container(
          color: kSurface,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ...widget.examTypes.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _examType = e.key); _loadData(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _examType == e.key ? kAccent.withOpacity(0.2) : kSurface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _examType == e.key ? kAccent : Colors.transparent),
                    ),
                    child: Text(e.value, style: TextStyle(color: _examType == e.key ? kAccent : kTextSecondary, fontSize: 13)),
                  ),
                ),
              )),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Soru Ekle'),
                style: TextButton.styleFrom(foregroundColor: kAccent),
                onPressed: () => _showAddQuestion(context),
              ),
              if (_questions != null && _questions!.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analiz'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
                  onPressed: _runAnalysis,
                ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results != null
                  ? _ResultsTable(results: _results!)
                  : _QuestionsTab(
                      questions: _questions ?? [],
                      scores: _scores ?? {},
                      students: ref.read(appDataProvider).students,
                      onScoreChanged: (qId, sId, val) async {
                        await SupabaseService.saveQuestionScore(
                          questionId: qId,
                          studentId: sId,
                          score: val,
                        );
                        await _loadData();
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddQuestion(BuildContext context) {
    final maxCtrl = TextEditingController(text: '10');
    final topicCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Yeni Soru', style: TextStyle(color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: kTextPrimary),
              decoration: InputDecoration(
                labelText: 'Maksimum puan',
                labelStyle: TextStyle(color: kTextSecondary),
                filled: true, fillColor: kSurface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: topicCtrl,
              style: TextStyle(color: kTextPrimary),
              decoration: InputDecoration(
                labelText: 'Konu (opsiyonel)',
                labelStyle: TextStyle(color: kTextSecondary),
                filled: true, fillColor: kSurface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () async {
              final max = double.tryParse(maxCtrl.text) ?? 10.0;
              // Insert via SQL-like insert — we reuse saveGrade-like pattern
              // For simplicity, save as exam question via Supabase directly
              await Supabase.instance.client.from('exam_questions').insert({
                'user_id': Supabase.instance.client.auth.currentUser?.id,
                'semester': widget.semester,
                'exam_type': _examType,
                'q_number': (_questions?.length ?? 0) + 1,
                'max_points': max,
                'topic': topicCtrl.text.trim().isEmpty ? null : topicCtrl.text.trim(),
              });
              await _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: Text('Ekle', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

class _QuestionsTab extends StatelessWidget {
  final List<ExamQuestion> questions;
  final Map<String, double> scores;
  final List<dynamic> students;
  final Future<void> Function(String qId, String sId, double val) onScoreChanged;
  const _QuestionsTab({
    required this.questions,
    required this.scores,
    required this.students,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz, color: kTextSecondary, size: 48),
            const SizedBox(height: 12),
            Text('Soru eklenmemiş.', style: TextStyle(color: kTextSecondary)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kSurface),
          dataRowColor: WidgetStateProperty.resolveWith((s) => kSurface2),
          columnSpacing: 12,
          columns: [
            DataColumn(label: Text('Öğrenci', style: TextStyle(color: kAccent, fontSize: 12))),
            ...questions.map((q) => DataColumn(
              label: SizedBox(
                width: 60,
                child: Text('S${q.qNumber}\n(/${q.maxPoints.toInt()})', style: TextStyle(color: kTextSecondary, fontSize: 10), textAlign: TextAlign.center),
              ),
              numeric: true,
            )),
          ],
          rows: students.map((s) => DataRow(
            cells: [
              DataCell(SizedBox(width: 100, child: Text(s.name, style: TextStyle(color: kTextPrimary, fontSize: 12), overflow: TextOverflow.ellipsis))),
              ...questions.map((q) {
                final score = scores['${q.id}_${s.id}'];
                return DataCell(
                  GestureDetector(
                    onTap: () => _editScore(context, q, s, score),
                    child: Container(
                      width: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: score != null ? kAccent.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        score != null ? score.toStringAsFixed(0) : '-',
                        style: TextStyle(color: score != null ? kTextPrimary : kTextSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                );
              }),
            ],
          )).toList(),
        ),
      ),
    );
  }

  void _editScore(BuildContext context, ExamQuestion q, dynamic s, double? current) {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('${s.name} — S${q.qNumber}', style: TextStyle(color: kTextPrimary, fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            labelText: 'Puan (max: ${q.maxPoints.toInt()})',
            labelStyle: TextStyle(color: kTextSecondary),
            filled: true, fillColor: kSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () async {
              final val = ctrl.text.isEmpty ? 0.0 : (double.tryParse(ctrl.text) ?? 0.0);
              await onScoreChanged(q.id, s.id, val.clamp(0, q.maxPoints));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Kaydet', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  final List<ItemAnalysisResult> results;
  const _ResultsTable({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  SizedBox(width: 40, child: Text('S#', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700))),
                  Expanded(child: Text('Konu', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700))),
                  SizedBox(width: 60, child: Text('p', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                  SizedBox(width: 60, child: Text('d', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                  SizedBox(width: 80, child: Text('Değerl.', style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                ],
              ),
              const Divider(color: kSurface2, height: 16),
              ...results.map((r) {
                final pColor = r.difficulty >= 0.40 ? kAccent : r.difficulty >= 0.20 ? Colors.orange : kRed;
                final dColor = r.discrimination >= 0.30 ? kAccent : r.discrimination >= 0.20 ? Colors.orange : kRed;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('S${r.question.qNumber}', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Text(r.question.topic ?? '—', style: TextStyle(color: kTextSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Text(r.difficulty.toStringAsFixed(2), style: TextStyle(color: pColor, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
                            Text(r.difficultyLabel, style: TextStyle(color: pColor.withOpacity(0.7), fontSize: 9), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Text(r.discrimination.toStringAsFixed(2), style: TextStyle(color: dColor, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
                            Text(r.discriminationLabel, style: TextStyle(color: dColor.withOpacity(0.7), fontSize: 9), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: dColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r.discriminationLabel,
                            style: TextStyle(color: dColor, fontSize: 10, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
