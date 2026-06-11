import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_config.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.config, required this.onGoToLogin});

  final AppConfig config;
  final VoidCallback onGoToLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  String? _info;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Tüm alanları doldurun.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    setState(() => _submitting = true);
    final authState = context.read<AuthState>();
    final error = await authState.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: widget.config.role,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (error != null) {
        _error = error;
      } else {
        _info = 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.';
      }
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
                  '${widget.config.roleLabel} Kaydı',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Ad Soyad'),
                ),
                const SizedBox(height: 12),
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
                if (_info != null) ...[
                  const SizedBox(height: 12),
                  Text(_info!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.success)),
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
                      : const Text('Kayıt Ol'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: widget.onGoToLogin,
                  child: const Text('Zaten hesabın var mı? Giriş yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
