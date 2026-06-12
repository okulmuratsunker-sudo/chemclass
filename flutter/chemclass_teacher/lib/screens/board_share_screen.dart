import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/snack.dart';
import 'board_view_screen.dart';

/// Tahta Modu (host) - mirrors `index.html`'s `#boardShare` section: pick the
/// class + code validity, create/refresh/close a 6-digit board code, choose
/// the board's current view, and open the board viewer locally.
class BoardShareScreen extends StatefulWidget {
  const BoardShareScreen({super.key});

  @override
  State<BoardShareScreen> createState() => _BoardShareScreenState();
}

class _BoardShareScreenState extends State<BoardShareScreen> {
  final _enterCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _enterCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final classes = app.data.classes;
    final hasCode = app.activeBoardCode.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('🖥️ PIN\'li Tahta Modu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
                const SizedBox(height: 6),
                Text(
                  'Akıllı tahtada kullanıcı adı/şifre görünmeden sadece görüntüleme ekranı açılır. '
                  'Puan girişi ve düzenleme kapalıdır.',
                  style: TextStyle(color: cc.text2, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text('Tahtada gösterilecek sınıf', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: classes.contains(app.selectedShareClass) ? app.selectedShareClass : null,
                  items: [for (final c in classes) DropdownMenuItem(value: c, child: Text(c))],
                  hint: const Text('Sınıf seçin'),
                  onChanged: (v) {
                    app.selectedShareClass = v ?? '';
                    app.notify();
                  },
                ),
                const SizedBox(height: 10),
                Text('Kod geçerlilik süresi', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: app.shareHours,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('2 saat')),
                    DropdownMenuItem(value: 4, child: Text('4 saat')),
                    DropdownMenuItem(value: 8, child: Text('8 saat')),
                    DropdownMenuItem(value: 12, child: Text('12 saat')),
                  ],
                  onChanged: (v) {
                    app.shareHours = v ?? app.shareHours;
                    app.notify();
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(onPressed: () => _create(context, app), child: const Text('Tahta Kodu Oluştur')),
                    OutlinedButton(onPressed: () => _refresh(context, app), child: const Text('Tahtayı Güncelle')),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
                      onPressed: () => _close(context, app),
                      child: const Text('Bağlantıyı Kapat'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cc.green.withValues(alpha: 0.06),
                    border: Border.all(color: cc.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Tahta Kodu: ', style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
                          Text(
                            hasCode ? app.activeBoardCode : 'Henüz yok',
                            style: TextStyle(fontSize: 28, color: cc.green, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCode
                            ? '${app.activeBoardClass} sınıfı için ${app.shareHours} saat geçerli.'
                            : 'Kod oluşturmak için önce bulut hesabına giriş yapmalısın.',
                        style: TextStyle(color: cc.text2, fontSize: 12),
                      ),
                      if (hasCode) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: () => _copyCode(context, app), child: const Text('Kodu Kopyala')),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('Tahta görünümü:', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ViewButton(label: '📊 Liste', view: 'list', app: app),
                    _ViewButton(label: '🎲 Seçici', view: 'pick', app: app),
                    _ViewButton(label: '👥 Gruplar', view: 'groups', app: app),
                    _ViewButton(label: '⏱️ Sayaç', view: 'timer', app: app),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Akıllı tahtada açılacak ekran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _enterCodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '6 haneli kod'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => _openBoard(context), child: const Text('Tahtayı Aç')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, AppState app) async {
    final err = await app.createBoardCode(app.selectedShareClass);
    if (err != null && context.mounted) showSnack(context, err);
  }

  Future<void> _refresh(BuildContext context, AppState app) async {
    final err = await app.manualRefreshBoard();
    if (err != null && context.mounted) showSnack(context, err);
  }

  Future<void> _close(BuildContext context, AppState app) async {
    final err = await app.closeBoardSession();
    if (err != null && context.mounted) showSnack(context, err);
  }

  void _copyCode(BuildContext context, AppState app) {
    Clipboard.setData(ClipboardData(text: app.activeBoardCode));
    showSnack(context, 'Tahta kodu kopyalandı: ${app.activeBoardCode}');
  }

  void _openBoard(BuildContext context) {
    final code = _enterCodeCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showSnack(context, '6 haneli kod girin');
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => BoardViewScreen(initialCode: code)));
  }
}

class _ViewButton extends StatelessWidget {
  final String label;
  final String view;
  final AppState app;
  const _ViewButton({required this.label, required this.view, required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final active = app.boardCurrentView == view;
    return OutlinedButton(
      onPressed: () {
        app.setBoardView(view);
        app.notify();
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? cc.green.withValues(alpha: 0.18) : null,
        foregroundColor: active ? cc.green : cc.text1,
        side: BorderSide(color: active ? cc.green.withValues(alpha: 0.5) : cc.border),
      ),
      child: Text(label),
    );
  }
}
