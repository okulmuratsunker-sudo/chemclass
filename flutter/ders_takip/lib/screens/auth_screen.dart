import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Login / sign-up screen, mirroring `ders-takip.html`'s `#authScreen`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _msg;
  bool _msgIsError = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    final app = context.read<AppState>();
    final result = _isLogin
        ? await app.signIn(_emailCtrl.text, _passCtrl.text)
        : await app.signUp(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!result.ok) {
        _msg = result.error;
        _msgIsError = true;
      } else if (result.needsConfirmation) {
        _msg = '✓ Kayıt başarılı! E-postanızı onaylayın, ardından giriş yapın.';
        _msgIsError = false;
      } else {
        _msg = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: dt.s1,
                  border: Border.all(color: dt.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
                        children: [
                          TextSpan(text: 'Ders', style: TextStyle(color: dt.text1)),
                          TextSpan(text: 'Takip', style: TextStyle(color: dt.green)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hesabınıza giriş yapın',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dt.text3, fontSize: 14),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: dt.s2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _AuthTab(label: 'Giriş Yap', active: _isLogin, onTap: () => setState(() { _isLogin = true; _msg = null; }))),
                          Expanded(child: _AuthTab(label: 'Kayıt Ol', active: !_isLogin, onTap: () => setState(() { _isLogin = false; _msg = null; }))),
                        ],
                      ),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_msgIsError ? dt.red : dt.green).withValues(alpha: 0.1),
                          border: Border.all(color: (_msgIsError ? dt.red : dt.green).withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_msg!, style: TextStyle(color: _msgIsError ? dt.red : dt.green, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-posta', hintText: 'ornek@mail.com'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Şifre', hintText: 'En az 6 karakter'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AuthTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? dt.s1 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? dt.text1 : dt.text2),
        ),
      ),
    );
  }
}
