import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/classes_repository.dart';
import '../../state/auth_state.dart';

class ClassesListScreen extends StatelessWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return ChangeNotifierProvider(
      create: (_) => StudentClassesController(profile.id),
      child: const _ClassesListView(),
    );
  }
}

class _ClassesListView extends StatefulWidget {
  const _ClassesListView();

  @override
  State<_ClassesListView> createState() => _ClassesListViewState();
}

class _ClassesListViewState extends State<_ClassesListView> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onJoin(StudentClassesController controller) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    final result = await joinClassByCode(code);
    if (!mounted) return;
    setState(() => _joining = false);
    if (result.error != null || result.data == null) {
      setState(() => _error = 'Geçersiz kod. Tekrar deneyin.');
      return;
    }
    _codeController.clear();
    controller.refetch();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentClassesController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıflarım')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Sınıf kodu (örn. AB12CD)', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _joining ? null : () => _onJoin(controller),
                child: _joining
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText))
                    : const Text('Katıl'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          if (controller.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (controller.classes.isEmpty)
            const Center(child: Text('Henüz bir sınıfa katılmadın.', style: TextStyle(color: AppColors.muted)))
          else
            for (final classRow in controller.classes)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/class/${classRow.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(classRow.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
