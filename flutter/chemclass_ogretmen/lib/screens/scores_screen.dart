import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/app_data.dart';
import '../providers/app_provider.dart';

class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});

  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final notifier = ref.read(appDataProvider.notifier);

    if (!notifier.loaded) return const Center(child: CircularProgressIndicator());
    if (data.classes.isEmpty) return Center(child: Text('Önce sınıf ekleyin.', style: TextStyle(color: kTextSecondary)));

    _selectedClass ??= data.classes.first;
    final students = data.studentsOf(_selectedClass!);
    final sorted = [...students]..sort((a, b) => b.score.compareTo(a.score));

    return Column(
      children: [
        // Class tabs
        Container(
          color: kSurface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        // Custom buttons
        _CustomButtons(buttons: data.customBtns, students: students, notifier: notifier),
        // Leaderboard
        Expanded(
          child: sorted.isEmpty
              ? Center(child: Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: kTextSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ScoreCard(
                    rank: i + 1,
                    student: sorted[i],
                    notifier: notifier,
                    customButtons: data.customBtns,
                  ),
                ),
        ),
        // Edit custom buttons
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kAccent.withOpacity(0.4)),
              foregroundColor: kAccent,
            ),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Özel Butonları Düzenle'),
            onPressed: () => _showEditButtons(context, data.customBtns, notifier),
          ),
        ),
      ],
    );
  }

  void _showEditButtons(BuildContext ctx, List<CustomButton> current, AppDataNotifier notifier) {
    final list = current.map((b) => CustomButton(val: b.val, label: b.label)).toList();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditButtonsSheet(initial: list, onSave: (btns) {
        notifier.saveCustomButtons(btns);
        Navigator.pop(ctx);
      }),
    );
  }
}

class _CustomButtons extends StatelessWidget {
  final List<CustomButton> buttons;
  final List<Student> students;
  final AppDataNotifier notifier;
  const _CustomButtons({required this.buttons, required this.students, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox();
    return Container(
      color: kSurface2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tüm Sınıfa Uygula:', style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: buttons.map((btn) => GestureDetector(
              onTap: () => _showPickStudent(context, btn),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: btn.val > 0 ? kAccent.withOpacity(0.15) : kRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: btn.val > 0 ? kAccent.withOpacity(0.4) : kRed.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${btn.val > 0 ? '+' : ''}${btn.val} ${btn.label}',
                  style: TextStyle(
                    color: btn.val > 0 ? kAccent : kRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showPickStudent(BuildContext ctx, CustomButton btn) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Öğrenci Seç: ${btn.label}', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
          ),
          ...students.map((s) => ListTile(
            leading: CircleAvatar(
              backgroundColor: kAvatarColors[s.color % kAvatarColors.length].withOpacity(0.2),
              child: Text(s.name[0], style: TextStyle(color: kAvatarColors[s.color % kAvatarColors.length])),
            ),
            title: Text(s.name, style: TextStyle(color: kTextPrimary)),
            trailing: Text('${s.score} puan', style: TextStyle(color: kTextSecondary, fontSize: 12)),
            onTap: () {
              notifier.changeScore(s.id, btn.val, btn.label);
              Navigator.pop(ctx);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int rank;
  final Student student;
  final AppDataNotifier notifier;
  final List<CustomButton> customButtons;
  const _ScoreCard({required this.rank, required this.student, required this.notifier, required this.customButtons});

  @override
  Widget build(BuildContext context) {
    final color = kAvatarColors[student.color % kAvatarColors.length];
    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    else if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    else if (rank == 3) rankColor = const Color(0xFFCD7F32);
    else rankColor = kTextSecondary;

    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(student.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ),
            Positioned(
              bottom: -2,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        title: Text(student.name, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500)),
        subtitle: Text('No: ${student.no}', style: TextStyle(color: kTextSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${student.score}',
              style: TextStyle(
                color: student.score > 0 ? kAccent : student.score < 0 ? kRed : kTextSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text('puan', style: TextStyle(color: kTextSecondary, fontSize: 11)),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              color: kSurface2,
              icon: Icon(Icons.add_circle, color: kAccent, size: 22),
              tooltip: 'Puan Ver',
              onSelected: (val) => _showNoteDialog(context, val),
              itemBuilder: (_) => [
                ...customButtons.map((b) => PopupMenuItem(
                  value: b.val,
                  child: Text('${b.val > 0 ? '+' : ''}${b.val} ${b.label}', style: TextStyle(color: kTextPrimary)),
                )),
                const PopupMenuDivider(),
                PopupMenuItem(value: 999, child: Text('Özel...', style: TextStyle(color: kAccent))),
              ],
            ),
          ],
        ),
        iconColor: kTextSecondary,
        collapsedIconColor: kTextSecondary,
        children: [
          if (student.history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Henüz puan yok.', style: TextStyle(color: kTextSecondary)),
            )
          else
            ...student.history.reversed.take(10).map((e) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: e.delta > 0 ? kAccent.withOpacity(0.15) : kRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${e.delta > 0 ? '+' : ''}${e.delta}',
                      style: TextStyle(color: e.delta > 0 ? kAccent : kRed, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.note, style: TextStyle(color: kTextPrimary, fontSize: 13))),
                  Text(
                    '${e.dateTime.day}/${e.dateTime.month}',
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext ctx, int val) {
    if (val == 999) {
      // Custom value dialog
      final valCtrl = TextEditingController();
      final noteCtrl = TextEditingController();
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Özel Puan', style: TextStyle(color: kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                style: TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Puan (+/-)',
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true, fillColor: kSurface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Not',
                  labelStyle: TextStyle(color: kTextSecondary),
                  filled: true, fillColor: kSurface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
            TextButton(
              onPressed: () {
                final v = int.tryParse(valCtrl.text);
                if (v != null && noteCtrl.text.trim().isNotEmpty) {
                  notifier.changeScore(student.id, v, noteCtrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: Text('Ekle', style: TextStyle(color: kAccent)),
            ),
          ],
        ),
      );
    } else {
      final noteCtrl = TextEditingController();
      final label = customButtons.firstWhere((b) => b.val == val, orElse: () => CustomButton(val: val, label: 'Puan')).label;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('${val > 0 ? '+' : ''}$val $label', style: TextStyle(color: kTextPrimary)),
          content: TextField(
            controller: noteCtrl,
            autofocus: true,
            style: TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Not (opsiyonel)',
              labelStyle: TextStyle(color: kTextSecondary),
              filled: true, fillColor: kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
            TextButton(
              onPressed: () {
                notifier.changeScore(student.id, val, noteCtrl.text.trim().isEmpty ? label : noteCtrl.text.trim());
                Navigator.pop(ctx);
              },
              child: Text('Ekle', style: TextStyle(color: kAccent)),
            ),
          ],
        ),
      );
    }
  }
}

class _EditButtonsSheet extends StatefulWidget {
  final List<CustomButton> initial;
  final void Function(List<CustomButton>) onSave;
  const _EditButtonsSheet({required this.initial, required this.onSave});

  @override
  State<_EditButtonsSheet> createState() => _EditButtonsSheetState();
}

class _EditButtonsSheetState extends State<_EditButtonsSheet> {
  late List<CustomButton> _buttons;

  @override
  void initState() {
    super.initState();
    _buttons = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Özel Butonlar', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(onPressed: () => _addButton(), child: Text('+ Ekle', style: TextStyle(color: kAccent))),
              ],
            ),
          ),
          Expanded(
            child: _buttons.isEmpty
                ? Center(child: Text('Henüz buton yok.', style: TextStyle(color: kTextSecondary)))
                : ListView(
                    controller: ctrl,
                    children: _buttons.asMap().entries.map((e) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: e.value.val > 0 ? kAccent.withOpacity(0.15) : kRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${e.value.val > 0 ? '+' : ''}${e.value.val}',
                          style: TextStyle(color: e.value.val > 0 ? kAccent : kRed, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(e.value.label, style: TextStyle(color: kTextPrimary)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: kRed, size: 20),
                        onPressed: () => setState(() => _buttons.removeAt(e.key)),
                      ),
                    )).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kBg),
                onPressed: () => widget.onSave(_buttons),
                child: const Text('Kaydet'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addButton() {
    final valCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Yeni Buton', style: TextStyle(color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              style: TextStyle(color: kTextPrimary),
              decoration: InputDecoration(
                labelText: 'Puan değeri (örn: +5 veya -1)',
                labelStyle: TextStyle(color: kTextSecondary),
                filled: true, fillColor: kSurface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              style: TextStyle(color: kTextPrimary),
              decoration: InputDecoration(
                labelText: 'Etiket (örn: Katılım)',
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
              final v = int.tryParse(valCtrl.text);
              if (v != null && labelCtrl.text.trim().isNotEmpty) {
                setState(() => _buttons.add(CustomButton(val: v, label: labelCtrl.text.trim())));
                Navigator.pop(context);
              }
            },
            child: Text('Ekle', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}
