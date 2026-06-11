import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/chat_view.dart';
import '../../state/auth_state.dart';

class MessageThreadScreen extends StatelessWidget {
  const MessageThreadScreen({super.key, required this.classId, required this.studentId, this.studentName});

  final String classId;
  final String studentId;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final teacherId = context.watch<AuthState>().profile?.id;
    if (teacherId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(studentName ?? 'Mesajlar')),
      body: ChatView(classId: classId, peerId: studentId, currentUserId: teacherId),
    );
  }
}
