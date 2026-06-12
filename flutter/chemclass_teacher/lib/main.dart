import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const ChemClassApp(),
    ),
  );
}

class ChemClassApp extends StatefulWidget {
  const ChemClassApp({super.key});

  @override
  State<ChemClassApp> createState() => _ChemClassAppState();
}

class _ChemClassAppState extends State<ChemClassApp> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'ChemClass',
      debugShowCheckedModeBanner: false,
      themeMode: app.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: app.ready ? const _ToastListener(child: HomeShell()) : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Scaffold(
      body: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 30),
            children: [
              TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
              TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Surfaces [AppState.toasts] as SnackBars app-wide, mirroring the web app's
/// `msg()` toast for async events (cloud sync, realtime chat).
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
