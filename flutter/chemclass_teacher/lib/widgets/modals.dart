import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Puan Geçmişi - mirrors `openHistModal()`.
Future<void> showHistoryDialog(BuildContext context, Student student) {
  final cc = Theme.of(context).cc;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${student.name} — Puan Geçmişi'),
      content: SizedBox(
        width: double.maxFinite,
        child: student.history.isEmpty
            ? Text('Henüz puan kaydı yok.', style: TextStyle(color: cc.text2))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final h in student.history)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${h.d > 0 ? '+' : ''}${h.d}',
                                style: TextStyle(
                                  color: h.d > 0 ? cc.green : cc.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Text(h.n)),
                            const SizedBox(width: 8),
                            Text(h.t, style: TextStyle(color: cc.text2, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
    ),
  );
}

/// Öğrenci Düzenle - mirrors `openEditStudent()` / `saveEditStudent()`.
Future<void> showEditStudentDialog(BuildContext context, AppState app, Student student) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _EditStudentDialog(app: app, student: student),
  );
}

class _EditStudentDialog extends StatefulWidget {
  final AppState app;
  final Student student;
  const _EditStudentDialog({required this.app, required this.student});

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noCtrl;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _noCtrl = TextEditingController(text: widget.student.no);
    _color = widget.student.color.clamp(0, avatarFg.length - 1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return AlertDialog(
      title: const Text('Öğrenci Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ad Soyad', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Ad Soyad')),
            const SizedBox(height: 8),
            Text('Okul Numarası', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(controller: _noCtrl, decoration: const InputDecoration(hintText: 'No')),
            const SizedBox(height: 8),
            Text('Avatar Rengi', style: TextStyle(color: cc.text2, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(avatarFg.length, (i) {
                final selected = i == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: avatarFg[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? cc.text1 : Colors.transparent, width: 3),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            final ok = widget.app.editStudent(widget.student.id, _nameCtrl.text, _noCtrl.text, _color);
            if (ok) {
              Navigator.pop(context);
              widget.app.toast('Öğrenci güncellendi');
            } else {
              widget.app.toast('Ad Soyad boş olamaz');
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// ↔️ Öğrenci Taşı - mirrors `openTransfer()` / `doTransfer()`.
Future<void> showTransferDialog(BuildContext context, AppState app, Student student) {
  final others = app.data.classes.where((c) => c != student.className).toList();
  if (others.isEmpty) {
    app.toast('Taşınacak başka sınıf yok');
    return Future<void>.value();
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => _TransferDialog(app: app, student: student, others: others),
  );
}

class _TransferDialog extends StatefulWidget {
  final AppState app;
  final Student student;
  final List<String> others;
  const _TransferDialog({required this.app, required this.student, required this.others});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  late String _target;

  @override
  void initState() {
    super.initState();
    _target = widget.others.first;
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return AlertDialog(
      title: const Text('↔️ Öğrenci Taşı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.student.name} — Şu an: ${widget.student.className}', style: TextStyle(color: cc.text2)),
          const SizedBox(height: 10),
          Text('Hedef Sınıf', style: TextStyle(color: cc.text2, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _target,
            items: [for (final c in widget.others) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _target = v ?? _target),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            final s = widget.student;
            widget.app.transferStudent(s.id, _target);
            Navigator.pop(context);
            widget.app.toast('${s.name} → $_target');
          },
          child: const Text('Taşı'),
        ),
      ],
    );
  }
}

/// ⚙️ Özel Puan Butonları - mirrors `showCustomBtnModal()` / `saveCustomBtns()`.
Future<void> showCustomButtonsDialog(BuildContext context, AppState app) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CustomButtonsDialog(app: app),
  );
}

class _CustomButtonsDialog extends StatefulWidget {
  final AppState app;
  const _CustomButtonsDialog({required this.app});

  @override
  State<_CustomButtonsDialog> createState() => _CustomButtonsDialogState();
}

class _CustomButtonsDialogState extends State<_CustomButtonsDialog> {
  late List<CustomButton> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.app.data.customBtns.map((b) => CustomButton(val: b.val, label: b.label)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return AlertDialog(
      title: const Text('⚙️ Özel Puan Butonları'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kendi puan butonlarını ekle (örn: +5 Proje, −2 Devamsızlık).',
                style: TextStyle(color: cc.text2, fontSize: 12),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '${_items[i].val}',
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          decoration: const InputDecoration(hintText: 'Puan'),
                          onChanged: (v) => _items[i].val = int.tryParse(v) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _items[i].label,
                          decoration: const InputDecoration(hintText: 'Buton adı'),
                          onChanged: (v) => _items[i].label = v,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _items.removeAt(i)),
                        icon: Icon(Icons.close, color: cc.red),
                      ),
                    ],
                  ),
                ),
              OutlinedButton(
                onPressed: () => setState(() => _items.add(CustomButton(val: 5, label: 'Proje'))),
                child: const Text('+ Yeni Buton Ekle'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            widget.app.saveCustomButtons(_items);
            Navigator.pop(context);
            widget.app.toast('Butonlar kaydedildi');
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// 📊 Yoklama İstatistikleri - mirrors `showAttStats()`.
Future<void> showAttStatsDialog(BuildContext context, AppState app, String className) {
  final cc = Theme.of(context).cc;
  final result = app.attStats(className);
  Widget content;
  if (result == null) {
    content = Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: cc.text2));
  } else if (result.rows.isEmpty) {
    content = Text('Henüz yoklama kaydı yok.', style: TextStyle(color: cc.text2));
  } else {
    final rows = result.rows;
    content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${rows.first.total} günlük kayıt (${result.from} – ${result.to})',
            style: TextStyle(color: cc.text2, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.symmetric(inside: BorderSide(color: cc.border)),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(children: [
                  _cell('Öğrenci', cc.text2, bold: true, align: TextAlign.left),
                  _cell('No', cc.text2, bold: true),
                  _cell('✓ Geldi', cc.green, bold: true),
                  _cell('✗ Gelmedi', cc.red, bold: true),
                  _cell('⚡ İzinli', cc.gold, bold: true),
                  _cell('% Devam', cc.text1, bold: true),
                ]),
                for (final r in rows)
                  TableRow(children: [
                    _cell(r.name, cc.text1, bold: true, align: TextAlign.left),
                    _cell(r.no.isEmpty ? '-' : r.no, cc.text2),
                    _cell('${r.present}', cc.green, bold: true),
                    _cell('${r.absent}', cc.red, bold: true),
                    _cell('${r.excused}', cc.gold, bold: true),
                    _cell('${r.attendancePercent}%', cc.text1, bold: true),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('📊 Yoklama İstatistikleri'),
      content: SizedBox(width: double.maxFinite, child: content),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
    ),
  );
}

Widget _cell(String text, Color color, {bool bold = false, TextAlign align = TextAlign.center}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      text,
      textAlign: align,
      style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 13),
    ),
  );
}
