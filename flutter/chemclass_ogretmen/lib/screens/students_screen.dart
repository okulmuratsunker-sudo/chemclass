import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/app_data.dart';
import '../providers/app_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final notifier = ref.read(appDataProvider.notifier);

    if (!notifier.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.classes.isEmpty) {
      return _EmptyState(onAdd: () => _showAddClassDialog(context, notifier));
    }

    _selectedClass ??= data.classes.first;

    return Column(
      children: [
        // Class tabs
        Container(
          color: kSurface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ...data.classes.map((cls) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ClassTab(
                    label: cls,
                    selected: _selectedClass == cls,
                    onTap: () => setState(() => _selectedClass = cls),
                    onLongPress: () => _showClassMenu(context, cls, notifier),
                  ),
                )),
                GestureDetector(
                  onTap: () => _showAddClassDialog(context, notifier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: kAccent.withOpacity(0.4), style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: kAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('Sınıf Ekle', style: TextStyle(color: kAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Class code bar
        if (_selectedClass != null) _ClassCodeBar(
          className: _selectedClass!,
          code: data.classCodes[_selectedClass] ?? '------',
          onRegen: () => notifier.regenClassCode(_selectedClass!),
        ),
        // Student list
        Expanded(
          child: _selectedClass == null
              ? const SizedBox()
              : _StudentList(
                  className: _selectedClass!,
                  students: data.studentsOf(_selectedClass!),
                  allClasses: data.classes,
                  notifier: notifier,
                ),
        ),
      ],
    );
  }

  void _showAddClassDialog(BuildContext context, AppDataNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Yeni Sınıf', style: TextStyle(color: kTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Örn: 10-A',
            hintStyle: TextStyle(color: kTextSecondary),
            filled: true,
            fillColor: kSurface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.addClass(ctrl.text.trim());
                setState(() => _selectedClass = ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text('Ekle', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  void _showClassMenu(BuildContext context, String className, AppDataNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(className, style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.delete, color: kRed),
            title: Text('Sınıfı Sil', style: TextStyle(color: kRed)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteClass(context, className, notifier);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, String className, AppDataNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Sınıfı Sil', style: TextStyle(color: kTextPrimary)),
        content: Text(
          '$className sınıfı ve tüm öğrencileri silinecek. Emin misiniz?',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteClass(className);
              setState(() => _selectedClass = null);
              Navigator.pop(context);
            },
            child: Text('Sil', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }
}

class _ClassTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _ClassTab({required this.label, required this.selected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kAccent : kSurface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kBg : kTextSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClassCodeBar extends StatelessWidget {
  final String className;
  final String code;
  final VoidCallback onRegen;
  const _ClassCodeBar({required this.className, required this.code, required this.onRegen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code, color: kAccent, size: 20),
          const SizedBox(width: 10),
          Text(
            'Sınıf Kodu: ',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          Text(
            code,
            style: TextStyle(
              color: kAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.copy, color: kTextSecondary, size: 18),
            tooltip: 'Kopyala',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kod kopyalandı: $code'),
                  backgroundColor: kSurface2,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: kTextSecondary, size: 18),
            tooltip: 'Yeni Kod',
            onPressed: onRegen,
          ),
        ],
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  final String className;
  final List<Student> students;
  final List<String> allClasses;
  final AppDataNotifier notifier;
  const _StudentList({
    required this.className,
    required this.students,
    required this.allClasses,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: students.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, color: kTextSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('Henüz öğrenci yok', style: TextStyle(color: kTextSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _StudentCard(
                student: students[i],
                allClasses: allClasses,
                notifier: notifier,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        icon: const Icon(Icons.person_add),
        label: const Text('Öğrenci Ekle'),
        onPressed: () => _showAddStudentDialog(context),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final noCtrl = TextEditingController();
    int selectedColor = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Öğrenci Ekle', style: TextStyle(color: kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true,
                  fillColor: kSurface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noCtrl,
                style: TextStyle(color: kTextPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Okul No',
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true,
                  fillColor: kSurface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Renk:', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  ...kAvatarColors.asMap().entries.map((e) => GestureDetector(
                    onTap: () => setS(() => selectedColor = e.key),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: selectedColor == e.key
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: TextStyle(color: kTextSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  notifier.addStudent(Student.create(
                    className,
                    nameCtrl.text.trim(),
                    noCtrl.text.trim(),
                    color: selectedColor,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: Text('Ekle', style: TextStyle(color: kAccent)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final List<String> allClasses;
  final AppDataNotifier notifier;
  const _StudentCard({required this.student, required this.allClasses, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final color = kAvatarColors[student.color % kAvatarColors.length];
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(student.name, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500)),
        subtitle: Text('No: ${student.no}', style: TextStyle(color: kTextSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${student.score} puan',
                style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              color: kSurface2,
              icon: Icon(Icons.more_vert, color: kTextSecondary, size: 20),
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: kAccent, size: 18), const SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: kTextPrimary))])),
                PopupMenuItem(value: 'transfer', child: Row(children: [Icon(Icons.swap_horiz, color: kAccent, size: 18), const SizedBox(width: 8), Text('Sınıf Değiştir', style: TextStyle(color: kTextPrimary))])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: kRed, size: 18), const SizedBox(width: 8), Text('Sil', style: TextStyle(color: kRed))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Öğrenciyi Sil', style: TextStyle(color: kTextPrimary)),
          content: Text('${student.name} silinecek. Emin misiniz?', style: TextStyle(color: kTextSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
            TextButton(
              onPressed: () { notifier.deleteStudent(student.id); Navigator.pop(context); },
              child: Text('Sil', style: TextStyle(color: kRed)),
            ),
          ],
        ),
      );
    } else if (action == 'transfer') {
      final otherClasses = allClasses.where((c) => c != student.className).toList();
      if (otherClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başka sınıf yok.'), backgroundColor: kSurface2),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Sınıf Değiştir', style: TextStyle(color: kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: otherClasses.map((cls) => ListTile(
              title: Text(cls, style: TextStyle(color: kTextPrimary)),
              onTap: () { notifier.transferStudent(student.id, cls); Navigator.pop(context); },
            )).toList(),
          ),
        ),
      );
    } else if (action == 'edit') {
      final nameCtrl = TextEditingController(text: student.name);
      final noCtrl = TextEditingController(text: student.no);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Düzenle', style: TextStyle(color: kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true, fillColor: kSurface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noCtrl,
                style: TextStyle(color: kTextPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Okul No',
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
              onPressed: () {
                notifier.updateStudent(student.copyWith(name: nameCtrl.text.trim(), no: noCtrl.text.trim()));
                Navigator.pop(context);
              },
              child: Text('Kaydet', style: TextStyle(color: kAccent)),
            ),
          ],
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: kTextSecondary, size: 64),
          const SizedBox(height: 16),
          Text('Henüz sınıf yok', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('İlk sınıfınızı ekleyerek başlayın', style: TextStyle(color: kTextSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kBg),
            icon: const Icon(Icons.add),
            label: const Text('Sınıf Ekle'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
