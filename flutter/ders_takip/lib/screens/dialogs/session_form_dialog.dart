import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lesson_session.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/snack.dart';

/// Add/edit lesson dialog, mirroring `ders-takip.html`'s `sessionForm()`
/// including the auto-calculated amount (`calcAmount()`).
Future<void> showSessionFormDialog(
  BuildContext context,
  AppState app, {
  LessonSession? session,
  String? preStudentId,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _SessionFormDialog(session: session, preStudentId: preStudentId),
  );
}

class _SessionFormDialog extends StatefulWidget {
  final LessonSession? session;
  final String? preStudentId;
  const _SessionFormDialog({this.session, this.preStudentId});

  @override
  State<_SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<_SessionFormDialog> {
  String? _studentId;
  late TextEditingController _dateCtrl;
  late TextEditingController _durCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  bool _paid = false;
  String _hint = 'Öğrenci ve süre girilince otomatik hesaplanır';

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _studentId = s?.studentId ?? widget.preStudentId;
    _dateCtrl = TextEditingController(text: s != null ? s.date.substring(0, 10) : localDate());
    _durCtrl = TextEditingController(text: s != null ? _numStr(s.duration) : '');
    _amountCtrl = TextEditingController(text: s != null ? _numStr(s.amount) : '');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _paid = s?.paid ?? false;
    _calcAmount();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _durCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _calcAmount() {
    final app = context.read<AppState>();
    final matches = app.students.where((x) => x.id == _studentId);
    if (matches.isEmpty) return;
    final student = matches.first;
    final dur = double.tryParse(_durCtrl.text.replaceAll(',', '.'));
    if (dur != null && dur > 0) {
      final calc = student.hourlyRate * dur;
      _amountCtrl.text = calc.toStringAsFixed(2);
      _hint = '${fmtDur(dur)} × ${fmt(student.hourlyRate)} = ${fmt(calc)}';
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = localDate(picked));
    }
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    if (_studentId == null) {
      showSnack(context, 'Öğrenci seçin');
      return;
    }
    final date = _dateCtrl.text.trim();
    if (date.isEmpty) {
      showSnack(context, 'Tarih girin');
      return;
    }
    final dur = double.tryParse(_durCtrl.text.replaceAll(',', '.'));
    if (dur == null || dur <= 0) {
      showSnack(context, 'Geçerli süre girin');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount < 0) {
      showSnack(context, 'Geçerli tutar girin');
      return;
    }
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    await app.saveSession(
      id: widget.session?.id,
      studentId: _studentId!,
      date: date,
      duration: dur,
      amount: amount,
      paid: _paid,
      notes: notes,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;

    return AlertDialog(
      title: Text(widget.session == null ? 'Yeni Ders' : 'Dersi Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _studentId,
              decoration: const InputDecoration(labelText: 'Öğrenci'),
              items: app.students
                  .map((st) => DropdownMenuItem(value: st.id, child: Text(st.name)))
                  .toList(),
              onChanged: (val) => setState(() {
                _studentId = val;
                _calcAmount();
              }),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(labelText: 'Tarih', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Süre (saat)', hintText: '1.5'),
                    onChanged: (_) => setState(_calcAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tutar (₺)', hintText: 'Otomatik hesaplanır'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_hint, style: TextStyle(fontSize: 11, color: dt.text3)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)', hintText: 'Konu, hatırlatma...'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _paid,
              onChanged: (v) => setState(() => _paid = v ?? false),
              title: const Text('Ödendi'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}

String _numStr(double n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toString();
}
