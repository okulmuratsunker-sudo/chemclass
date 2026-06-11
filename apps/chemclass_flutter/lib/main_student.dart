import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'state/auth_state.dart';
import 'student/student_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ChemClassStudentApp());
}

class ChemClassStudentApp extends StatefulWidget {
  const ChemClassStudentApp({super.key});

  @override
  State<ChemClassStudentApp> createState() => _ChemClassStudentAppState();
}

class _ChemClassStudentAppState extends State<ChemClassStudentApp> {
  late final AuthState _authState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authState = AuthState();
    _router = buildStudentRouter(_authState);
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
        title: 'ChemClass Öğrenci',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
