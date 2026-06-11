import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_config.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.config, required this.onGoToSignup});

  final AppConfig config;
  final VoidCallback onGoToSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'E-posta ve şifre gerekli.');
      return;
    }
    setState(() => _submitting = true);
    final authState = context.read<AuthState>();
    final error = await authState.signIn(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.config.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.config.roleLabel} Girişi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(hintText: 'E-posta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Şifre'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitting ? null : _onSubmit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText),
                        )
                      : const Text('Giriş Yap'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: widget.onGoToSignup,
                  child: const Text('Hesabın yok mu? Kayıt ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
