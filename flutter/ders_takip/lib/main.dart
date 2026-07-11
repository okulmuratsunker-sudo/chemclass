import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const DersTakipApp(),
    ),
  );
}

class DersTakipApp extends StatelessWidget {
  const DersTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'DersTakip',
      debugShowCheckedModeBanner: false,
      themeMode: app.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: !app.ready
          ? const _SplashScreen()
          : _ToastListener(child: app.isAuthed ? const HomeShell() : const AuthScreen()),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Scaffold(
      body: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 28),
            children: [
              TextSpan(text: 'Ders', style: TextStyle(color: dt.text1)),
              TextSpan(text: 'Takip', style: TextStyle(color: dt.green)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Surfaces [AppState.toasts] as SnackBars app-wide, mirroring the web app's
/// `toast()` helper.
class _ToastListener extends StatefulWidget {
  final Widget child;
  const _ToastListener({required this.child});

  @override
  State<_ToastListener> createState() => _ToastListenerState();
}

class _ToastListenerState extends State<_ToastListener> {
  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    app.toasts.listen((text) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(text)));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
