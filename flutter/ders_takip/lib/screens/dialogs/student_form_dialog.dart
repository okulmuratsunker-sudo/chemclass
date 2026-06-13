import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../providers/app_state.dart';
import '../../utils/snack.dart';

/// Add/edit student dialog, mirroring `ders-takip.html`'s `studentForm()`.
Future<void> showStudentFormDialog(BuildContext context, AppState app, {Student? student}) {
  final nameCtrl = TextEditingController(text: student?.name ?? '');
  final rateCtrl = TextEditingController(text: student != null ? _numStr(student.hourlyRate) : '');

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(student == null ? 'Yeni Öğrenci' : 'Öğrenciyi Düzenle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Ad Soyad', hintText: 'Öğrenci adı'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Saatlik Ücret (₺)', hintText: 'Örn: 500'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            final rate = double.tryParse(rateCtrl.text.replaceAll(',', '.'));
            if (name.isEmpty) {
              showSnack(ctx, 'Ad gerekli');
              return;
            }
            if (rate == null || rate < 0) {
              showSnack(ctx, 'Geçerli bir ücret girin');
              return;
            }
            await app.saveStudent(id: student?.id, name: name, hourlyRate: rate);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

String _numStr(double n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toString();
}
