import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../services/supabase_service.dart';

final _plansProvider = FutureProvider<List<LessonPlan>>((ref) async {
  return SupabaseService.loadLessonPlans();
});

class LessonPlansScreen extends ConsumerStatefulWidget {
  const LessonPlansScreen({super.key});

  @override
  ConsumerState<LessonPlansScreen> createState() => _LessonPlansScreenState();
}

class _LessonPlansScreenState extends ConsumerState<LessonPlansScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_plansProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text('Ders Planları', style: TextStyle(color: kTextPrimary)),
        iconTheme: IconThemeData(color: kTextSecondary),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: kSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(label: 'Tümü', value: 'all', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: '📅 Günlük', value: 'gun', selected: _filter == 'gun', onTap: () => setState(() => _filter = 'gun')),
                  const SizedBox(width: 8),
                  _FilterChip(label: '📖 Ünite', value: 'unite', selected: _filter == 'unite', onTap: () => setState(() => _filter = 'unite')),
                  const SizedBox(width: 8),
                  _FilterChip(label: '📆 Yıllık', value: 'yillik', selected: _filter == 'yillik', onTap: () => setState(() => _filter = 'yillik')),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
              data: (plans) {
                final filtered = _filter == 'all' ? plans : plans.where((p) => p.planType == _filter).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories, color: kTextSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('Henüz plan yok.', style: TextStyle(color: kTextSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PlanCard(
                    plan: filtered[i],
                    onEdit: () => _showSheet(context, existing: filtered[i]),
                    onDelete: () async {
                      await SupabaseService.deleteLessonPlan(filtered[i].id);
                      ref.invalidate(_plansProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Plan'),
        onPressed: () => _showSheet(context),
      ),
    );
  }

  void _showSheet(BuildContext context, {LessonPlan? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlanSheet(
        existing: existing,
        onSaved: () {
          ref.invalidate(_plansProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final LessonPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanCard({required this.plan, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(plan.planType == 'gun' ? '📅' : plan.planType == 'unite' ? '📖' : '📆', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(plan.title, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.date != null)
              Text(
                DateFormat('d MMMM yyyy', 'tr_TR').format(plan.date!),
                style: TextStyle(color: kAccent, fontSize: 12),
              ),
            if (plan.content != null && plan.content!.isNotEmpty)
              Text(
                plan.content!,
                style: TextStyle(color: kTextSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: kSurface2,
          icon: Icon(Icons.more_vert, color: kTextSecondary, size: 20),
          onSelected: (a) => a == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text('Düzenle', style: TextStyle(color: kTextPrimary))),
            PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: kRed))),
          ],
        ),
        onTap: () => _showContent(context),
      ),
    );
  }

  void _showContent(BuildContext context) {
    if (plan.content == null || plan.content!.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(plan.title, style: TextStyle(color: kTextPrimary)),
        content: SingleChildScrollView(child: Text(plan.content!, style: TextStyle(color: kTextSecondary))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Kapat', style: TextStyle(color: kAccent))),
        ],
      ),
    );
  }
}

class _PlanSheet extends StatefulWidget {
  final LessonPlan? existing;
  final VoidCallback onSaved;
  const _PlanSheet({this.existing, required this.onSaved});

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late String _type;
  DateTime? _date;
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.planType ?? 'gun';
    _date = widget.existing?.date;
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Yeni Plan' : 'Planı Düzenle',
            style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          // Type selector
          Row(
            children: [
              _FilterChip(label: '📅 Günlük', value: 'gun', selected: _type == 'gun', onTap: () => setState(() => _type = 'gun')),
              const SizedBox(width: 8),
              _FilterChip(label: '📖 Ünite', value: 'unite', selected: _type == 'unite', onTap: () => setState(() => _type = 'unite')),
              const SizedBox(width: 8),
              _FilterChip(label: '📆 Yıllık', value: 'yillik', selected: _type == 'yillik', onTap: () => setState(() => _type = 'yillik')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Başlık',
              labelStyle: TextStyle(color: kTextSecondary),
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: kAccent, surface: kSurface)),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: kAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _date != null ? DateFormat('d MMMM yyyy', 'tr_TR').format(_date!) : 'Tarih seç (opsiyonel)',
                    style: TextStyle(color: _date != null ? kTextPrimary : kTextSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            style: TextStyle(color: kTextPrimary),
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'İçerik',
              labelStyle: TextStyle(color: kTextSecondary),
              alignLabelWithHint: true,
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kBg),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kBg, strokeWidth: 2))
                  : const Text('Kaydet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.saveLessonPlan(
        id: widget.existing?.id,
        planType: _type,
        title: _titleCtrl.text.trim(),
        date: _date,
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
      );
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAccent.withOpacity(0.2) : kSurface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kAccent : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: selected ? kAccent : kTextSecondary, fontSize: 13)),
      ),
    );
  }
}
