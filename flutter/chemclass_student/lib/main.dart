import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const ChemClassStudentApp(),
    ),
  );
}

class ChemClassStudentApp extends StatelessWidget {
  const ChemClassStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'ChemClass Öğrenci',
      debugShowCheckedModeBanner: false,
      themeMode: app.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: !app.ready
          ? const _SplashScreen()
          : _ToastListener(child: app.loggedIn ? const HomeShell() : const LoginScreen()),
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

/// Surfaces [AppState.toasts] as SnackBars app-wide (new message/assignment
/// notifications while the app is open).
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
