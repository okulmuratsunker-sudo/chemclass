import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../services/supabase_service.dart';

final _portfolioStudentsProvider = FutureProvider<List<TeacherStudent>>((ref) async {
  return SupabaseService.loadTeacherStudents();
});

class TeacherPortfolioScreen extends ConsumerStatefulWidget {
  const TeacherPortfolioScreen({super.key});

  @override
  ConsumerState<TeacherPortfolioScreen> createState() => _TeacherPortfolioScreenState();
}

class _TeacherPortfolioScreenState extends ConsumerState<TeacherPortfolioScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_portfolioStudentsProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text('Öğretmenim Portfolyosu', style: TextStyle(color: kTextPrimary)),
        iconTheme: IconThemeData(color: kTextSecondary),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
        data: (students) {
          final classes = students.map((s) => s.className).toSet().toList()..sort();
          _selectedClass ??= classes.isNotEmpty ? classes.first : null;
          final filtered = _selectedClass == null
              ? students
              : students.where((s) => s.className == _selectedClass).toList();

          return Column(
            children: [
              // Class selector
              if (classes.isNotEmpty)
                Container(
                  color: kSurface,
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
                              color: _selectedClass == cls ? kAccent : kSurface2,
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
              // Student list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, color: kTextSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text('Öğrenci eklenmemiş.', style: TextStyle(color: kTextSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PortfolioStudentCard(
                          student: filtered[i],
                          onEdit: () => _showEditSheet(context, filtered[i]),
                          onDelete: () async {
                            await SupabaseService.deleteTeacherStudent(filtered[i].id);
                            ref.invalidate(_portfolioStudentsProvider);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        icon: const Icon(Icons.person_add),
        label: const Text('Öğrenci Ekle'),
        onPressed: () => _showEditSheet(context, null),
      ),
    );
  }

  void _showEditSheet(BuildContext context, TeacherStudent? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StudentEditSheet(
        existing: existing,
        onSaved: () {
          ref.invalidate(_portfolioStudentsProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _PortfolioStudentCard extends StatelessWidget {
  final TeacherStudent student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PortfolioStudentCard({required this.student, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kAccent.withOpacity(0.15),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(student.name, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No: ${student.studentNumber} • ${student.className}', style: TextStyle(color: kTextSecondary, fontSize: 12)),
            if (student.notes != null && student.notes!.isNotEmpty)
              Text(student.notes!, style: TextStyle(color: kTextSecondary.withOpacity(0.7), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: kSurface2,
          icon: Icon(Icons.more_vert, color: kTextSecondary, size: 20),
          onSelected: (a) => a == 'edit' ? onEdit() : _confirmDelete(context),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text('Düzenle', style: TextStyle(color: kTextPrimary))),
            PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: kRed))),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Sil', style: TextStyle(color: kTextPrimary)),
        content: Text('${student.name} silinecek.', style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(onPressed: () { Navigator.pop(context); onDelete(); }, child: Text('Sil', style: TextStyle(color: kRed))),
        ],
      ),
    );
  }
}

class _StudentEditSheet extends StatefulWidget {
  final TeacherStudent? existing;
  final VoidCallback onSaved;
  const _StudentEditSheet({this.existing, required this.onSaved});

  @override
  State<_StudentEditSheet> createState() => _StudentEditSheetState();
}

class _StudentEditSheetState extends State<_StudentEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _noCtrl;
  late TextEditingController _classCtrl;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _noCtrl = TextEditingController(text: widget.existing?.studentNumber ?? '');
    _classCtrl = TextEditingController(text: widget.existing?.className ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noCtrl.dispose();
    _classCtrl.dispose();
    _notesCtrl.dispose();
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
            widget.existing == null ? 'Öğrenci Ekle' : 'Öğrenciyi Düzenle',
            style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _Field(ctrl: _nameCtrl, label: 'Ad Soyad *'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Field(ctrl: _noCtrl, label: 'Okul No', keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Field(ctrl: _classCtrl, label: 'Sınıf')),
            ],
          ),
          const SizedBox(height: 12),
          _Field(ctrl: _notesCtrl, label: 'Notlar (opsiyonel)', maxLines: 3),
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
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.saveTeacherStudent(
        id: widget.existing?.id,
        name: _nameCtrl.text.trim(),
        studentNumber: _noCtrl.text.trim(),
        className: _classCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  final int maxLines;
  const _Field({required this.ctrl, required this.label, this.keyboard, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kTextSecondary),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: kSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
