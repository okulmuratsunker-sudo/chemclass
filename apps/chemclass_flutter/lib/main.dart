import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'state/auth_state.dart';
import 'teacher/teacher_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ChemClassTeacherApp());
}

class ChemClassTeacherApp extends StatefulWidget {
  const ChemClassTeacherApp({super.key});

  @override
  State<ChemClassTeacherApp> createState() => _ChemClassTeacherAppState();
}

class _ChemClassTeacherAppState extends State<ChemClassTeacherApp> {
  late final AuthState _authState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authState = AuthState();
    _router = buildTeacherRouter(_authState);
  }

  @override
  void dispose() {
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authState,
      child: MaterialApp.router(
        title: 'ChemClass',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
