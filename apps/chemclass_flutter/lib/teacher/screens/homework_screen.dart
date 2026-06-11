import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime_list.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RealtimeListController<Homework>(
        table: 'homework',
        fromJson: Homework.fromJson,
        match: {'class_id': classId},
        compare: (a, b) => b.createdAt.compareTo(a.createdAt),
      ),
      child: _HomeworkView(classId: classId),
    );
  }
}

class _HomeworkView extends StatefulWidget {
  const _HomeworkView({required this.classId});

  final String classId;

  @override
  State<_HomeworkView> createState() => _HomeworkViewState();
}

class _HomeworkViewState extends State<_HomeworkView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final title = _titleController.text.trim();
    final profile = context.read<AuthState>().profile;
    if (title.isEmpty || profile == null) return;
    setState(() => _sending = true);
    try {
      await supabase.from('homework').insert({
        'class_id': widget.classId,
        'created_by': profile.id,
        'title': title,
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'due_date': _dueDateController.text.trim().isEmpty ? null : _dueDateController.text.trim(),
      });
      _titleController.clear();
      _descriptionController.clear();
      _dueDateController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onDelete(String id) async {
    await supabase.from('homework').delete().eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RealtimeListController<Homework>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ödevler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Yeni Ödev', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Başlık')),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Açıklama'),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dueDateController,
            decoration: const InputDecoration(hintText: 'Teslim tarihi (örn. 2026-06-20)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (_sending || _titleController.text.trim().isEmpty) ? null : _onCreate,
            child: _sending
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText))
                : const Text('Ödev Ver'),
          ),
          const SizedBox(height: 16),
          const Text('Ödevler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (controller.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (controller.items.isEmpty)
            const Text('Henüz ödev yok.', style: TextStyle(color: AppColors.muted))
          else
            for (final item in controller.items)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (item.description != null && item.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(item.description!, style: const TextStyle(color: AppColors.muted)),
                          ],
                          if (item.dueDate != null) ...[
                            const SizedBox(height: 4),
                            Text('Teslim: ${item.dueDate}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ],
                      ),
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
