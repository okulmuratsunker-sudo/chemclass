import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/snack.dart';

/// Bulut Senkronizasyonu - mirrors `index.html`'s `#cloud` section.
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _urlCtrl = TextEditingController(text: app.sbUrl);
    _keyCtrl = TextEditingController(text: app.sbKey);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('☁️ Bulut Senkronizasyonu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 6),
            Text(
              'Bu bölüm isteğe bağlıdır. E-posta/şifre ile giriş yaparsan veriler cihazlar arasında senkronize olur.',
              style: TextStyle(color: cc.text2, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text('Supabase Project URL', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(hintText: 'https://xxxx.supabase.co')),
            const SizedBox(height: 8),
            Text('Supabase anon public key', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(controller: _keyCtrl, decoration: const InputDecoration(hintText: 'anon public key'), maxLines: 2),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => app.saveCloudSettings(_urlCtrl.text, _keyCtrl.text),
                  child: const Text('Ayarları Kaydet'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _urlCtrl.text = app.sbUrl;
                    _keyCtrl.text = app.sbKey;
                  }),
                  child: const Text('Ayarları Yükle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: cc.border),
            const SizedBox(height: 12),
            Text('E-posta', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'ornek@mail.com'),
            ),
            const SizedBox(height: 8),
            Text('Şifre', style: TextStyle(color: cc.text2, fontSize: 12)),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Şifre'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final err = await app.signUp(_emailCtrl.text, _passCtrl.text);
                    if (err != null && context.mounted) showSnack(context, err);
                  },
                  child: const Text('Hesap Oluştur'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final err = await app.signIn(_emailCtrl.text, _passCtrl.text);
                    if (err != null && context.mounted) showSnack(context, err);
                  },
                  child: const Text('Giriş Yap'),
                ),
                OutlinedButton(
                  onPressed: app.sbUser == null ? null : () => _confirmSignOut(context, app),
                  style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
                  child: const Text('Çıkış'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: app.loadFromCloud, child: const Text('Buluttan Yükle')),
                OutlinedButton(onPressed: app.saveToCloudNow, child: const Text('Buluta Kaydet')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cc.green.withValues(alpha: 0.06),
                border: Border.all(color: cc.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: cc.text1, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Durum: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: app.cloudInfoText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Çıkış yapılınca cihazdaki tüm yerel veriler temizlenecek. Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış Yap')),
        ],
      ),
    );
    if (ok == true) await app.signOut();
  }
}
