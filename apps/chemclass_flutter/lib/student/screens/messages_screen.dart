import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/classes_repository.dart';
import '../../shared/widgets/chat_view.dart';
import '../../state/auth_state.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassController(classId),
      child: _MessagesView(classId: classId),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final studentId = context.watch<AuthState>().profile?.id;
    final classController = context.watch<ClassController>();
    final classRow = classController.classRow;

    if (studentId == null || classController.loading || classRow == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: ChatView(classId: classId, peerId: classRow.teacherId, currentUserId: studentId),
    );
  }
}
