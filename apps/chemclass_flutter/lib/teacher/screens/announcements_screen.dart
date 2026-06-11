import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime_list.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RealtimeListController<Announcement>(
        table: 'announcements',
        fromJson: Announcement.fromJson,
        match: {'class_id': classId},
        compare: (a, b) => b.createdAt.compareTo(a.createdAt),
      ),
      child: _AnnouncementsView(classId: classId),
    );
  }
}

class _AnnouncementsView extends StatefulWidget {
  const _AnnouncementsView({required this.classId});

  final String classId;

  @override
  State<_AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<_AnnouncementsView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onShare() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final profile = context.read<AuthState>().profile;
    if (title.isEmpty || content.isEmpty || profile == null) return;
    setState(() => _sending = true);
    try {
      await supabase.from('announcements').insert({
        'class_id': widget.classId,
        'created_by': profile.id,
        'title': title,
        'content': content,
      });
      _titleController.clear();
      _contentController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onDelete(String id) async {
    await supabase.from('announcements').delete().eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RealtimeListController<Announcement>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Duyurular')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Yeni Duyuru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Başlık')),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(hintText: 'İçerik'),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (_sending || _titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty)
                ? null
                : _onShare,
            child: _sending
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText))
                : const Text('Paylaş'),
          ),
          const SizedBox(height: 16),
          const Text('Duyurular', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (controller.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (controller.items.isEmpty)
            const Text('Henüz duyuru yok.', style: TextStyle(color: AppColors.muted))
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
                          const SizedBox(height: 4),
                          Text(item.content, style: const TextStyle(color: AppColors.muted)),
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
