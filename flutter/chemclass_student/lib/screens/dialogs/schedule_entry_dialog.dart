import 'package:flutter/material.dart';

import '../../models/schedule_entry.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/snack.dart';

/// "Ders Ekle / Düzenle" dialog for a single "Ders Programı" entry.
Future<void> showScheduleEntryDialog(
  BuildContext context,
  AppState app, {
  required int day,
  ScheduleEntry? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ScheduleEntryDialog(app: app, day: day, existing: existing),
  );
}

class _ScheduleEntryDialog extends StatefulWidget {
  final AppState app;
  final int day;
  final ScheduleEntry? existing;
  const _ScheduleEntryDialog({required this.app, required this.day, this.existing});

  @override
  State<_ScheduleEntryDialog> createState() => _ScheduleEntryDialogState();
}

class _ScheduleEntryDialogState extends State<_ScheduleEntryDialog> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _roomCtrl;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _color;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subjectCtrl = TextEditingController(text: e?.subject ?? '');
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _start = _parseTime(e?.startTime) ?? const TimeOfDay(hour: 8, minute: 0);
    _end = _parseTime(e?.endTime) ?? const TimeOfDay(hour: 8, minute: 40);
    _color = e?.color ?? 0;
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _start : _end);
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) {
      showSnack(context, 'Ders adını gir');
      return;
    }
    final entry = ScheduleEntry(
      id: widget.existing?.id ?? uid(),
      day: widget.day,
      startTime: _fmt(_start),
      endTime: _fmt(_end),
      subject: subject,
      room: _roomCtrl.text.trim(),
      color: _color,
    );
    if (widget.existing == null) {
      await widget.app.addScheduleEntry(entry);
    } else {
      await widget.app.updateScheduleEntry(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return AlertDialog(
      title: Text(widget.existing == null ? '➕ Ders Ekle' : '✏️ Dersi Düzenle'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ders Adı', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: _subjectCtrl, decoration: const InputDecoration(hintText: 'Kimya')),
              const SizedBox(height: 10),
              Text('Sınıf / Yer (isteğe bağlı)', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: _roomCtrl, decoration: const InputDecoration(hintText: 'B-12')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text('Başlangıç: ${_fmt(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text('Bitiş: ${_fmt(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Renk', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < avatarFg.length; i++)
                    InkWell(
                      onTap: () => setState(() => _color = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: avatarFg[i],
                          borderRadius: BorderRadius.circular(8),
                          border: _color == i ? Border.all(color: cc.text1, width: 2) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () async {
              await widget.app.deleteScheduleEntry(widget.existing!.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: cc.red),
            child: const Text('Sil'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}
