import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/snack.dart';

/// Öğrenci Girişi — class join code (from the teacher's "Sınıflar" screen)
/// + the student's school number. No Supabase Auth account needed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  final _noCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _noCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final err = await app.login(_codeCtrl.text, _noCtrl.text);
    if (!mounted) return;
    if (err != null) showSnack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 34),
                    children: [
                      TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
                      TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Öğrenci', style: TextStyle(color: cc.text2, fontSize: 13)),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('👋 Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
                        const SizedBox(height: 4),
                        Text(
                          'Öğretmeninin sana verdiği 6 karakterlik sınıf kodunu ve okul numaranı gir.',
                          style: TextStyle(color: cc.text2, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Text('Sınıf Kodu', style: TextStyle(color: cc.text2, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 4),
                          decoration: const InputDecoration(hintText: 'ABC123'),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 14),
                        Text('Okul Numarası', style: TextStyle(color: cc.text2, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _noCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                          decoration: const InputDecoration(hintText: '12'),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: app.loading ? null : _submit,
                          child: Text(app.loading ? 'Giriş yapılıyor...' : '▶ Giriş Yap'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
