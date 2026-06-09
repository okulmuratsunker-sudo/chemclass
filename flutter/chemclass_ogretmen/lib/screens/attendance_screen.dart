import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/app_data.dart';
import '../providers/app_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final notifier = ref.read(appDataProvider.notifier);

    if (!notifier.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.classes.isEmpty) {
      return Center(child: Text('Önce sınıf ekleyin.', style: TextStyle(color: kTextSecondary)));
    }

    _selectedClass ??= data.classes.first;
    final students = data.studentsOf(_selectedClass!);
    final attendance = data.attendanceFor(_selectedClass!, _selectedDate);

    return Column(
      children: [
        // Header controls
        Container(
          color: kSurface,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Class selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: data.classes.map((cls) => Padding(
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
                        child: Text(
                          cls,
                          style: TextStyle(
                            color: _selectedClass == cls ? kBg : kTextSecondary,
                            fontWeight: _selectedClass == cls ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Date selector
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, color: kAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(_selectedDate),
                        style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: kTextSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Stats bar
        _StatsBar(students: students, attendance: attendance),
        // Student list
        Expanded(
          child: students.isEmpty
              ? Center(child: Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: kTextSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final status = attendance[s.id] ?? '';
                    return _AttendanceCard(
                      student: s,
                      status: status,
                      onChanged: (val) => notifier.setAttendance(
                        _selectedClass!, _selectedDate, s.id, val,
                      ),
                    );
                  },
                ),
        ),
        // Mark all buttons
        Container(
          color: kSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('Tümünü işaretle:', style: TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(width: 12),
              _MarkAllBtn(label: 'P', color: kAccent, onTap: () {
                for (final s in students) {
                  notifier.setAttendance(_selectedClass!, _selectedDate, s.id, 'P');
                }
              }),
              const SizedBox(width: 8),
              _MarkAllBtn(label: 'G', color: kRed, onTap: () {
                for (final s in students) {
                  notifier.setAttendance(_selectedClass!, _selectedDate, s.id, 'A');
                }
              }),
              const SizedBox(width: 8),
              _MarkAllBtn(label: 'İ', color: Colors.orange, onTap: () {
                for (final s in students) {
                  notifier.setAttendance(_selectedClass!, _selectedDate, s.id, 'E');
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kAccent, surface: kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _StatsBar extends StatelessWidget {
  final List<Student> students;
  final Map<String, String> attendance;
  const _StatsBar({required this.students, required this.attendance});

  @override
  Widget build(BuildContext context) {
    int present = 0, absent = 0, excused = 0, unmarked = 0;
    for (final s in students) {
      final v = attendance[s.id] ?? '';
      if (v == 'P') present++;
      else if (v == 'A') absent++;
      else if (v == 'E') excused++;
      else unmarked++;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kSurface2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('Var', present, kAccent),
          _Stat('Yok', absent, kRed),
          _Stat('İzinli', excused, Colors.orange),
          _Stat('Belirsiz', unmarked, kTextSecondary),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Stat(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Student student;
  final String status;
  final void Function(String) onChanged;
  const _AttendanceCard({required this.student, required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = kAvatarColors[student.color % kAvatarColors.length];
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(student.name, style: TextStyle(color: kTextPrimary)),
        subtitle: Text('No: ${student.no}', style: TextStyle(color: kTextSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBtn(label: 'P', selected: status == 'P', color: kAccent, onTap: () => onChanged('P')),
            const SizedBox(width: 6),
            _StatusBtn(label: 'G', selected: status == 'A', color: kRed, onTap: () => onChanged('A')),
            const SizedBox(width: 6),
            _StatusBtn(label: 'İ', selected: status == 'E', color: Colors.orange, onTap: () => onChanged('E')),
          ],
        ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MarkAllBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MarkAllBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
