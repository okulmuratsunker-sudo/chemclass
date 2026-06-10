import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/message.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

final _assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  return SupabaseService.loadAssignments();
});

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_assignmentsProvider);
    final appData = ref.watch(appDataProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment, color: kTextSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('Henüz ödev/duyuru yok.', style: TextStyle(color: kTextSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AssignmentCard(
              assignment: assignments[i],
              onDelete: () async {
                await SupabaseService.deleteAssignment(assignments[i].id);
                ref.invalidate(_assignmentsProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ekle'),
        onPressed: () => _showAddSheet(context, appData.classes),
      ),
    );
  }

  void _showAddSheet(BuildContext context, List<String> classes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAssignmentSheet(
        classes: classes,
        onSaved: () {
          ref.invalidate(_assignmentsProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onDelete;
  const _AssignmentCard({required this.assignment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    switch (assignment.type) {
      case 'odev': typeColor = const Color(0xFF3B82F6); break;
      case 'duyuru': typeColor = kAccent; break;
      case 'gorev': typeColor = const Color(0xFF10B981); break;
      default: typeColor = kTextSecondary;
    }

    final isOverdue = assignment.dueDate != null && assignment.dueDate!.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: typeColor, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(assignment.typeLabel, style: TextStyle(color: typeColor, fontSize: 11)),
                ),
                if (assignment.className != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(assignment.className!, style: TextStyle(color: kTextSecondary, fontSize: 11)),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: kTextSecondary, size: 18),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assignment.title,
              style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (assignment.body != null && assignment.body!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                assignment.body!,
                style: TextStyle(color: kTextSecondary, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (assignment.dueDate != null) ...[
                  Icon(
                    Icons.event,
                    size: 14,
                    color: isOverdue ? kRed : kTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM yyyy', 'tr_TR').format(assignment.dueDate!),
                    style: TextStyle(
                      color: isOverdue ? kRed : kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormat('d MMM yyyy HH:mm', 'tr_TR').format(assignment.createdAt),
                  style: TextStyle(color: kTextSecondary.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Sil', style: TextStyle(color: kTextPrimary)),
        content: Text('Bu kayıt silinecek. Emin misiniz?', style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: Text('Sil', style: TextStyle(color: kRed))),
        ],
      ),
    );
  }
}

class _AddAssignmentSheet extends StatefulWidget {
  final List<String> classes;
  final VoidCallback onSaved;
  const _AddAssignmentSheet({required this.classes, required this.onSaved});

  @override
  State<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<_AddAssignmentSheet> {
  String _type = 'duyuru';
  String? _className;
  DateTime? _dueDate;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _saving = false;

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
          Text('Yeni Kayıt', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // Type selector
          Row(
            children: [
              _TypeChip(label: '📘 Ödev', value: 'odev', selected: _type == 'odev', onTap: () => setState(() => _type = 'odev')),
              const SizedBox(width: 8),
              _TypeChip(label: '📢 Duyuru', value: 'duyuru', selected: _type == 'duyuru', onTap: () => setState(() => _type = 'duyuru')),
              const SizedBox(width: 8),
              _TypeChip(label: '✅ Görev', value: 'gorev', selected: _type == 'gorev', onTap: () => setState(() => _type = 'gorev')),
            ],
          ),
          const SizedBox(height: 12),
          // Class selector
          if (widget.classes.isNotEmpty) DropdownButtonFormField<String>(
            value: _className,
            dropdownColor: kSurface2,
            decoration: InputDecoration(
              labelText: 'Sınıf (opsiyonel)',
              labelStyle: TextStyle(color: kTextSecondary),
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            style: TextStyle(color: kTextPrimary),
            items: [
              DropdownMenuItem(value: null, child: Text('Tüm Sınıflar', style: TextStyle(color: kTextSecondary))),
              ...widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() => _className = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Başlık *',
              labelStyle: TextStyle(color: kTextSecondary),
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            style: TextStyle(color: kTextPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Açıklama (opsiyonel)',
              labelStyle: TextStyle(color: kTextSecondary),
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          if (_type == 'odev' || _type == 'gorev') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: kAccent, surface: kSurface)),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _dueDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: kAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _dueDate != null
                          ? 'Teslim: ${DateFormat('d MMMM yyyy', 'tr_TR').format(_dueDate!)}'
                          : 'Teslim tarihi seç...',
                      style: TextStyle(color: _dueDate != null ? kTextPrimary : kTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      await SupabaseService.saveAssignment(
        className: _className ?? '',
        type: _type,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
        dueDate: _dueDate,
      );
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.value, required this.selected, required this.onTap});

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
