import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../services/supabase_service.dart';

final _studentsProvider = FutureProvider<List<TeacherStudent>>((ref) async {
  return SupabaseService.loadTeacherStudents();
});

final _gradesProvider = FutureProvider<List<Grade>>((ref) async {
  return SupabaseService.loadGrades(null);
});

class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key});

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _cols = ['w1', 'w2', 'oral', 'perf', 'perf2', 'project', 'proj2'];
  final _colLabels = ['Sınav 1', 'Sınav 2', 'Sözlü', 'Perf.1', 'Perf.2', 'Proje 1', 'Proje 2'];

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
    return Column(
      children: [
        Container(
          color: kSurface,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: kAccent,
            labelColor: kAccent,
            unselectedLabelColor: kTextSecondary,
            tabs: const [Tab(text: '1. Dönem'), Tab(text: '2. Dönem')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _GradebookTab(semester: 1, cols: _cols, colLabels: _colLabels, ref: ref),
              _GradebookTab(semester: 2, cols: _cols, colLabels: _colLabels, ref: ref),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradebookTab extends ConsumerStatefulWidget {
  final int semester;
  final List<String> cols;
  final List<String> colLabels;
  final WidgetRef ref;
  const _GradebookTab({required this.semester, required this.cols, required this.colLabels, required this.ref});

  @override
  ConsumerState<_GradebookTab> createState() => _GradebookTabState();
}

class _GradebookTabState extends ConsumerState<_GradebookTab> {
  String? _selectedClass;

  @override
  Widget build(BuildContext ctx) {
    final studentsAsync = ref.watch(_studentsProvider);
    final gradesAsync = ref.watch(_gradesProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
      data: (allStudents) {
        final classes = allStudents.map((s) => s.className).toSet().toList()..sort();
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book, color: kTextSecondary, size: 48),
                const SizedBox(height: 12),
                Text('Not defterinde öğrenci yok.', style: TextStyle(color: kTextSecondary)),
                const SizedBox(height: 8),
                Text('Öğrencileri Öğretmenim sekmesinden ekleyin.', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          );
        }
        _selectedClass ??= classes.first;
        final students = allStudents.where((s) => s.className == _selectedClass).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return gradesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
          data: (grades) {
            final gradeMap = <String, Grade>{};
            for (final g in grades) {
              if (g.semester == widget.semester) gradeMap[g.studentId] = g;
            }

            return Column(
              children: [
                // Class selector
                Container(
                  color: kSurface2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: classes.map((cls) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedClass = cls),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _selectedClass == cls ? kAccent : kSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cls, style: TextStyle(
                              color: _selectedClass == cls ? kBg : kTextSecondary,
                              fontWeight: _selectedClass == cls ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 13,
                            )),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                // Grade table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(kSurface),
                        dataRowColor: WidgetStateProperty.resolveWith((s) =>
                          s.contains(WidgetState.selected) ? kAccent.withOpacity(0.1) : kSurface2),
                        columnSpacing: 16,
                        columns: [
                          DataColumn(label: Text('Öğrenci', style: TextStyle(color: kAccent, fontSize: 12))),
                          ...widget.colLabels.map((l) => DataColumn(
                            label: Text(l, style: TextStyle(color: kTextSecondary, fontSize: 11)),
                            numeric: true,
                          )),
                          DataColumn(label: Text('Ort.', style: TextStyle(color: kAccent, fontSize: 12)), numeric: true),
                        ],
                        rows: students.map((s) {
                          final g = gradeMap[s.id];
                          final vals = g == null ? List<double?>.filled(7, null) : [g.w1, g.w2, g.oral, g.perf, g.perf2, g.project, g.proj2];
                          final avg = g?.donemInt;
                          return DataRow(
                            cells: [
                              DataCell(SizedBox(
                                width: 100,
                                child: Text(s.name, style: TextStyle(color: kTextPrimary, fontSize: 12), overflow: TextOverflow.ellipsis),
                              )),
                              ...vals.asMap().entries.map((e) => DataCell(
                                GestureDetector(
                                  onTap: () => _editGrade(s, widget.cols[e.key], e.value, gradeMap),
                                  child: Container(
                                    width: 52,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: e.value != null ? kAccent.withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      e.value != null ? e.value!.toStringAsFixed(0) : '-',
                                      style: TextStyle(
                                        color: e.value != null ? kTextPrimary : kTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: avg != null ? _gradeColor(avg).withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  avg != null ? '$avg' : '-',
                                  style: TextStyle(
                                    color: avg != null ? _gradeColor(avg) : kTextSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _gradeColor(int grade) {
    if (grade >= 85) return kAccent;
    if (grade >= 70) return const Color(0xFF3B82F6);
    if (grade >= 55) return Colors.orange;
    if (grade >= 50) return Colors.yellow;
    return kRed;
  }

  void _editGrade(TeacherStudent student, String col, double? current, Map<String, Grade> gradeMap) {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          '${student.name} — ${widget.colLabels[widget.cols.indexOf(col)]}',
          style: TextStyle(color: kTextPrimary, fontSize: 14),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            labelText: 'Not (0-100)',
            labelStyle: TextStyle(color: kTextSecondary),
            filled: true, fillColor: kSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () async {
              final val = ctrl.text.isEmpty ? null : double.tryParse(ctrl.text);
              await SupabaseService.saveGrade(
                studentId: student.id,
                semester: widget.semester,
                column: col,
                value: val,
              );
              ref.invalidate(_gradesProvider);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Kaydet', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}
