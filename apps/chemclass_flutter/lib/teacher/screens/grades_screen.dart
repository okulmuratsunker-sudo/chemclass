import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../data/classes_repository.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime_list.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassRosterController(classId)),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<Grade>(
            table: 'grades',
            fromJson: Grade.fromJson,
            match: {'class_id': classId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
      ],
      child: _GradesView(classId: classId),
    );
  }
}

class _GradesView extends StatefulWidget {
  const _GradesView({required this.classId});

  final String classId;

  @override
  State<_GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<_GradesView> {
  final _titleController = TextEditingController();
  final _scoreController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  String? _selectedStudentId;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final title = _titleController.text.trim();
    final score = num.tryParse(_scoreController.text.trim());
    final maxScore = num.tryParse(_maxScoreController.text.trim());
    final profile = context.read<AuthState>().profile;
    final studentId = _selectedStudentId;
    if (title.isEmpty || profile == null || studentId == null || score == null || maxScore == null) return;
    setState(() => _sending = true);
    try {
      await supabase.from('grades').insert({
        'class_id': widget.classId,
        'student_id': studentId,
        'given_by': profile.id,
        'title': title,
        'score': score,
        'max_score': maxScore,
      });
      _titleController.clear();
      _scoreController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onDelete(String id) async {
    await supabase.from('grades').delete().eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    final rosterController = context.watch<ClassRosterController>();
    final gradesController = context.watch<RealtimeListController<Grade>>();

    final studentNames = {
      for (final entry in rosterController.roster)
        if (entry.profile != null) entry.studentId: entry.profile!.fullName,
    };

    final canSubmit = !_sending &&
        _selectedStudentId != null &&
        _titleController.text.trim().isNotEmpty &&
        _scoreController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Notlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Yeni Not', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (rosterController.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (rosterController.roster.isEmpty)
            const Text('Bu sınıfa henüz öğrenci katılmadı.', style: TextStyle(color: AppColors.muted))
          else
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rosterController.roster.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = rosterController.roster[index];
                  final selected = entry.studentId == _selectedStudentId;
                  return ChoiceChip(
                    label: Text(entry.profile?.fullName ?? 'İsimsiz'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedStudentId = entry.studentId),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primaryText : AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Sınav / Ödev adı')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scoreController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Puan'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.muted)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxScoreController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Üst Limit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: canSubmit ? _onCreate : null,
            child: _sending
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText))
                : const Text('Notu Kaydet'),
          ),
          const SizedBox(height: 16),
          const Text('Notlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (gradesController.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (gradesController.items.isEmpty)
            const Text('Henüz not girilmedi.', style: TextStyle(color: AppColors.muted))
          else
            for (final item in gradesController.items)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentNames[item.studentId] ?? 'Öğrenci', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(item.title, style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text(
                      '${item.score}/${item.maxScore}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      onPressed: () => _onDelete(item.id),
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
