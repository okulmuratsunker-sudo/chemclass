import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../services/supabase_service.dart';
import '../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeCtrl = TextEditingController();
  final _noCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _noCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeCtrl.text.trim();
    final no = _noCtrl.text.trim();
    if (code.isEmpty || no.isEmpty) {
      setState(() => _error = 'Tüm alanları doldurun.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await SupabaseService.login(code, no);
      if (session == null) {
        setState(() => _error = 'Geçersiz sınıf kodu veya okul numarası.');
      } else {
        await ref.read(sessionProvider.notifier).login(session);
      }
    } catch (e) {
      setState(() => _error = 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.rajdhani(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                    children: const [
                      TextSpan(
                          text: 'CHEM',
                          style: TextStyle(color: kTextPrimary)),
                      TextSpan(
                          text: 'CLASS',
                          style: TextStyle(color: kAccent)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Öğrenci Girişi',
                  style: GoogleFonts.inter(
                    color: kTextSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),

                // Sınıf Kodu
                _InputField(
                  controller: _codeCtrl,
                  label: 'Sınıf Kodu',
                  hint: 'Öğretmeninizden aldığınız kod',
                  icon: Icons.key_rounded,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Okul Numarası
                _InputField(
                  controller: _noCtrl,
                  label: 'Okul Numarası',
                  hint: 'Okul numaranız',
                  icon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 12),

                // Hata mesajı
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kRed.withOpacity(0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                          color: kRed, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 8),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: kBg),
                          )
                        : Text(
                            'Giriş Yap',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: kTextSecondary, size: 20),
            filled: true,
            fillColor: kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kSurface2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kSurface2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
