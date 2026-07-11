import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/helpers.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';
import '../widgets/modals.dart';
import '../widgets/student_avatar.dart';

/// Sınıflar - mirrors `index.html`'s `#students` section: add class,
/// CSV/XLSX import, Excel export, end-of-term reset, search and the
/// per-class student lists with history/edit/transfer/delete actions.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _newClassCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, TextEditingController> _noCtrls = {};
  String _importStatus = 'Henüz dosya seçilmedi.';

  TextEditingController _nameCtrl(String cls) => _nameCtrls.putIfAbsent(cls, () => TextEditingController());
  TextEditingController _noCtrl(String cls) => _noCtrls.putIfAbsent(cls, () => TextEditingController());

  @override
  void dispose() {
    _newClassCtrl.dispose();
    _searchCtrl.dispose();
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final c in _noCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final query = trLower(_searchCtrl.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAddClassCard(context, app, cc),
        const SizedBox(height: 8),
        _buildImportCard(context, app, cc),
        const SizedBox(height: 8),
        _buildExportCard(context, app, cc),
        const SizedBox(height: 8),
        _buildResetCard(context, app, cc),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(hintText: '🔍 Öğrenci ara...'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (app.data.classes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Henüz sınıf yok.', style: TextStyle(color: cc.text2)),
            ),
          )
        else
          for (final c in app.data.classes) _buildClassCard(context, app, cc, c, query),
      ],
    );
  }

  Widget _buildAddClassCard(BuildContext context, AppState app, AppColors cc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sınıf Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 8),
            TextField(controller: _newClassCtrl, decoration: const InputDecoration(hintText: 'Örn: 9-A')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final name = _newClassCtrl.text.trim();
                if (name.isEmpty) {
                  showSnack(context, 'Sınıf adı girin');
                  return;
                }
                if (app.addClass(name)) {
                  _newClassCtrl.clear();
                  showSnack(context, 'Sınıf eklendi');
                } else {
                  showSnack(context, 'Bu sınıf zaten var');
                }
              },
              child: const Text('Sınıf Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard(BuildContext context, AppState app, AppColors cc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Excel / CSV Aktar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 8),
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedImportClass,
              onSelected: (c) {
                app.selectedImportClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => _pickImportFile(context, app), child: const Text('📁 Dosya Seç (.xlsx/.xls/.csv)')),
            const SizedBox(height: 6),
            Text(
              'CSV/XLSX: Okul Numarası ve Adı Soyadı sütunları aranır. Önce sınıf seç.',
              style: TextStyle(color: cc.text2, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(_importStatus, style: TextStyle(color: cc.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImportFile(BuildContext context, AppState app) async {
    if (app.selectedImportClass.isEmpty) {
      showSnack(context, 'Önce sınıf seçin');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final res = await app.importStudents(path, app.selectedImportClass);
    setState(() {
      _importStatus = res == null
          ? 'Dosya okunamadı.'
          : '${res.added} öğrenci eklendi, ${res.dup} zaten vardı, ${res.skipped} satır atlandı.';
    });
  }

  Widget _buildExportCard(BuildContext context, AppState app, AppColors cc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('📤 Excel\'e Aktar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 8),
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedExportClass,
              allowAll: true,
              onSelected: (c) {
                app.selectedExportClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _exportExcel(context, app), child: const Text('Excel İndir (.xlsx)')),
            const SizedBox(height: 6),
            Text('Seçili sınıfın puan tablosunu indirir.', style: TextStyle(color: cc.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, AppState app) async {
    final path = await app.exportToExcel(app.selectedExportClass);
    if (path == null) {
      if (context.mounted) showSnack(context, 'Öğrenci yok');
      return;
    }
    await Share.shareXFiles([XFile(path)]);
  }

  Widget _buildResetCard(BuildContext context, AppState app, AppColors cc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('⚙️ Dönem Sonu İşlemleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 8),
            ClassChips(
              classes: app.data.classes,
              selected: app.selectedResetClass,
              onSelected: (c) {
                app.selectedResetClass = c;
                app.notify();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
              onPressed: () => _resetScores(context, app),
              child: const Text('Puanları Sıfırla'),
            ),
            const SizedBox(height: 6),
            Text('Tüm puanları ve geçmişleri sıfırlar.', style: TextStyle(color: cc.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _resetScores(BuildContext context, AppState app) async {
    final cls = app.selectedResetClass;
    if (cls.isEmpty) {
      showSnack(context, 'Sınıf seçin');
      return;
    }
    final ok = await confirmDialog(
      context,
      'Puanları Sıfırla',
      '$cls sınıfının TÜM puanları ve geçmişleri sıfırlansın mı? Bu işlem geri alınamaz.',
      confirmLabel: 'Sıfırla',
    );
    if (ok) {
      app.resetScores(cls);
      if (context.mounted) showSnack(context, '$cls sınıfı sıfırlandı');
    }
  }

  Widget _buildClassCard(BuildContext context, AppState app, AppColors cc, String c, String query) {
    final all = app.getByClass(c);
    final ss = query.isEmpty
        ? all
        : all.where((s) => trLower(s.name).contains(query) || s.no.contains(query)).toList();
    final total = all.fold<int>(0, (a, s) => a + s.score);
    final code = app.getClassCode(c);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: c, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
                        TextSpan(
                          text: '  ${all.length} öğrenci • Toplam: ${total > 0 ? '+' : ''}$total',
                          style: TextStyle(color: cc.text2, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(onPressed: () => _clearClass(context, app, c), child: const Text('Temizle')),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
                  onPressed: () => _delClass(context, app, c),
                  child: const Text('Sil'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cc.green.withValues(alpha: 0.06),
                border: Border.all(color: cc.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Öğrenci Giriş Kodu:', style: TextStyle(color: cc.text2, fontSize: 12)),
                  Text(code, style: TextStyle(color: cc.green, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyCode(context, code),
                    icon: const Icon(Icons.copy, size: 16),
                  ),
                  OutlinedButton(
                    onPressed: () => app.regenClassCode(c),
                    child: const Text('Kodu Yenile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _nameCtrl(c), decoration: const InputDecoration(hintText: 'Ad Soyad'))),
                const SizedBox(width: 8),
                SizedBox(width: 90, child: TextField(controller: _noCtrl(c), decoration: const InputDecoration(hintText: 'No'))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _addStudent(context, app, c), child: const Text('Ekle')),
              ],
            ),
            for (final s in ss) _StudentRow(student: s, app: app),
            if (query.isNotEmpty && ss.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Arama sonucu yok.', style: TextStyle(color: cc.text2)),
              ),
          ],
        ),
      ),
    );
  }

  void _addStudent(BuildContext context, AppState app, String cls) {
    final name = _nameCtrl(cls).text;
    final no = _noCtrl(cls).text;
    if (app.addStudent(cls, name, no)) {
      _nameCtrl(cls).clear();
      _noCtrl(cls).clear();
      showSnack(context, 'Öğrenci eklendi');
    } else {
      showSnack(context, 'Ad Soyad girin');
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    showSnack(context, 'Kod kopyalandı: $code');
  }

  Future<void> _clearClass(BuildContext context, AppState app, String c) async {
    final ok = await confirmDialog(context, 'Sınıfı Temizle', '$c sınıfındaki öğrenciler silinsin mi?', confirmLabel: 'Temizle');
    if (ok) {
      app.clearClass(c);
      if (context.mounted) showSnack(context, 'Sınıf temizlendi');
    }
  }

  Future<void> _delClass(BuildContext context, AppState app, String c) async {
    final ok = await confirmDialog(context, 'Sınıfı Sil', '$c sınıfı ve tüm öğrencileri silinsin mi?', confirmLabel: 'Sil');
    if (ok) app.delClass(c);
  }
}

class _StudentRow extends StatelessWidget {
  final Student student;
  final AppState app;
  const _StudentRow({required this.student, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          StudentAvatar(student: student),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                Text(
                  'No: ${student.no.isEmpty ? '-' : student.no} • Puan: ${student.score > 0 ? '+' : ''}${student.score}',
                  style: TextStyle(color: cc.text2, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () => showHistoryDialog(context, student), icon: const Text('📋')),
          IconButton(onPressed: () => showEditStudentDialog(context, app, student), icon: const Text('✏️')),
          IconButton(onPressed: () => showTransferDialog(context, app, student), icon: const Text('↔️')),
          IconButton(onPressed: () => _delete(context), icon: Icon(Icons.delete_outline, color: cc.red)),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(context, 'Öğrenci Sil', 'Öğrenci silinsin mi?', confirmLabel: 'Sil');
    if (ok) app.delStudent(student.id);
  }
}
