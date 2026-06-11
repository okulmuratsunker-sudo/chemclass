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
      create: (_) => TeacherClassesController(profile.id),
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
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onCreate(TeacherClassesController controller, String teacherId) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    final result = await createClass(teacherId, name);
    if (!mounted) return;
    setState(() => _creating = false);
    if (result.error == null) {
      _nameController.clear();
      controller.refetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AuthState>().profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıflarım')),
      body: Consumer<TeacherClassesController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Yeni sınıf adı (örn. 10-A)', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _creating ? null : () => _onCreate(controller, profile.id),
                      child: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText),
                            )
                          : const Text('Ekle'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : controller.classes.isEmpty
                        ? const Center(
                            child: Text('Henüz sınıf eklenmedi.', style: TextStyle(color: AppColors.muted)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: controller.classes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final classRow = controller.classes[index];
                              return Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context.push('/class/${classRow.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(classRow.name,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Katılım kodu: ${classRow.joinCode}',
                                            style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
