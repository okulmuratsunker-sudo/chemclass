import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/assignment.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/snack.dart';

/// "Yeni Ödev / Duyuru / Görev" dialog - mirrors the web app's `saveAssignment()`
/// flow: pick a class + type, title/body, optional due date, optional file.
Future<void> showNewAssignmentDialog(BuildContext context, AppState app) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _NewAssignmentDialog(app: app),
  );
}

class _NewAssignmentDialog extends StatefulWidget {
  final AppState app;
  const _NewAssignmentDialog({required this.app});

  @override
  State<_NewAssignmentDialog> createState() => _NewAssignmentDialogState();
}

class _NewAssignmentDialogState extends State<_NewAssignmentDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _className = '';
  String _type = 'odev';
  DateTime? _dueDate;
  String? _filePath;
  String? _fileName;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final classes = widget.app.data.classes;
    final filter = widget.app.selectedAssignmentFilterClass;
    _className = classes.contains(filter) ? filter : (classes.isNotEmpty ? classes.first : '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final classes = widget.app.data.classes;
    return AlertDialog(
      title: const Text('📚 Yeni Ödev / Duyuru'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sınıf', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: classes.contains(_className) ? _className : null,
                items: [for (final c in classes) DropdownMenuItem(value: c, child: Text(c))],
                hint: const Text('Sınıf seçin'),
                onChanged: (v) => setState(() => _className = v ?? ''),
              ),
              const SizedBox(height: 10),
              Text('Tür', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _type,
                items: [for (final e in asgTypeLabel.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 10),
              Text('Başlık', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Başlık')),
              const SizedBox(height: 10),
              Text('Açıklama', style: TextStyle(color: cc.text2, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: _bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Açıklama (isteğe bağlı)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null ? 'Son tarih: yok' : 'Son tarih: ${todayStr(_dueDate)}',
                      style: TextStyle(color: cc.text2, fontSize: 12),
                    ),
                  ),
                  TextButton(onPressed: _pickDate, child: const Text('Tarih Seç')),
                  if (_dueDate != null) TextButton(onPressed: () => setState(() => _dueDate = null), child: const Text('Temizle')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fileName ?? 'Dosya eklenmedi',
                      style: TextStyle(color: cc.text2, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(onPressed: _pickFile, child: const Text('Dosya Ekle')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Gönderiliyor...' : 'Gönder'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() {
      _filePath = file!.path;
      _fileName = file.name;
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    Uint8List? bytes;
    if (_filePath != null) {
      bytes = await File(_filePath!).readAsBytes();
    }
    final err = await widget.app.saveAssignment(
      className: _className,
      type: _type,
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      dueDate: _dueDate != null ? todayStr(_dueDate) : null,
      fileName: _fileName,
      fileBytes: bytes,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _sending = false);
      showSnack(context, err);
    } else {
      Navigator.pop(context);
    }
  }
}
