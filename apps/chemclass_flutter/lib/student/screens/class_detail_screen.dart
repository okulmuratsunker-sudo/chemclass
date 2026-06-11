import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/classes_repository.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime_list.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final studentId = context.watch<AuthState>().profile?.id;
    if (studentId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassController(classId)),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<BehaviorPoint>(
            table: 'behavior_points',
            fromJson: BehaviorPoint.fromJson,
            match: {'class_id': classId, 'student_id': studentId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<Grade>(
            table: 'grades',
            fromJson: Grade.fromJson,
            match: {'class_id': classId, 'student_id': studentId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<Announcement>(
            table: 'announcements',
            fromJson: Announcement.fromJson,
            match: {'class_id': classId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<Homework>(
            table: 'homework',
            fromJson: Homework.fromJson,
            match: {'class_id': classId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
      ],
      child: _ClassDetailView(classId: classId),
    );
  }
}

class _ClassDetailView extends StatelessWidget {
  const _ClassDetailView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final classController = context.watch<ClassController>();
    final pointsController = context.watch<RealtimeListController<BehaviorPoint>>();
    final gradesController = context.watch<RealtimeListController<Grade>>();
    final announcementsController = context.watch<RealtimeListController<Announcement>>();
    final homeworkController = context.watch<RealtimeListController<Homework>>();
    final classRow = classController.classRow;

    if (classController.loading || classRow == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final totalPoints = pointsController.items.fold<int>(0, (sum, p) => sum + p.points);

    return Scaffold(
      appBar: AppBar(
        title: Text(classRow.name),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/class/$classId/messages'),
            icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
            label: const Text('Mesajlar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Davranış Puanlarım',
            trailing: Text(
              'Toplam: ${totalPoints > 0 ? '+$totalPoints' : '$totalPoints'}',
              style: TextStyle(fontWeight: FontWeight.bold, color: totalPoints >= 0 ? AppColors.success : AppColors.danger),
            ),
            child: pointsController.items.isEmpty
                ? const Text('Henüz puan kaydı yok.', style: TextStyle(color: AppColors.muted))
                : Column(
                    children: [
                      for (final item in pointsController.items)
                        _Row(
                          left: item.reason ?? 'Davranış puanı',
                          right: item.points > 0 ? '+${item.points}' : '${item.points}',
                          rightColor: item.points >= 0 ? AppColors.success : AppColors.danger,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Notlarım',
            child: gradesController.items.isEmpty
                ? const Text('Henüz not girilmedi.', style: TextStyle(color: AppColors.muted))
                : Column(
                    children: [
                      for (final item in gradesController.items)
                        _Row(left: item.title, right: '${item.score}/${item.maxScore}'),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Duyurular',
            child: announcementsController.items.isEmpty
                ? const Text('Henüz duyuru yok.', style: TextStyle(color: AppColors.muted))
                : Column(
                    children: [
                      for (final item in announcementsController.items)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(item.content, style: const TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Ödevler',
            child: homeworkController.items.isEmpty
                ? const Text('Henüz ödev yok.', style: TextStyle(color: AppColors.muted))
                : Column(
                    children: [
                      for (final item in homeworkController.items)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (item.description != null && item.description!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item.description!, style: const TextStyle(color: AppColors.muted)),
                              ],
                              if (item.dueDate != null) ...[
                                const SizedBox(height: 2),
                                Text('Teslim: ${item.dueDate}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.left, required this.right, this.rightColor});

  final String left;
  final String right;
  final Color? rightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(left, style: const TextStyle(color: AppColors.text))),
          const SizedBox(width: 8),
          Text(right, style: TextStyle(fontWeight: FontWeight.bold, color: rightColor ?? AppColors.primary)),
        ],
      ),
    );
  }
}
