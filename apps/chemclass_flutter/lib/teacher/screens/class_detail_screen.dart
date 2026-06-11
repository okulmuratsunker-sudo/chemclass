import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/behavior_points_repository.dart';
import '../../data/classes_repository.dart';
import '../../data/models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime_list.dart';

const _pointOptions = [-5, -1, 1, 5];

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

const _quickActions = [
  _QuickAction('Mesajlar', Icons.chat_bubble_outline, 'messages'),
  _QuickAction('Tahta', Icons.cast_outlined, 'board'),
  _QuickAction('Duyurular', Icons.campaign_outlined, 'announcements'),
  _QuickAction('Ödevler', Icons.menu_book_outlined, 'homework'),
  _QuickAction('Notlar', Icons.school_outlined, 'grades'),
];

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassController(classId)),
        ChangeNotifierProvider(create: (_) => ClassRosterController(classId)),
        ChangeNotifierProvider(
          create: (_) => RealtimeListController<BehaviorPoint>(
            table: 'behavior_points',
            fromJson: BehaviorPoint.fromJson,
            match: {'class_id': classId},
            compare: (a, b) => b.createdAt.compareTo(a.createdAt),
          ),
        ),
      ],
      child: _ClassDetailView(classId: classId),
    );
  }
}

class _ClassDetailView extends StatefulWidget {
  const _ClassDetailView({required this.classId});

  final String classId;

  @override
  State<_ClassDetailView> createState() => _ClassDetailViewState();
}

class _ClassDetailViewState extends State<_ClassDetailView> {
  String? _selectedStudentId;
  bool _sending = false;

  Future<void> _onGivePoint(int value) async {
    final profile = context.read<AuthState>().profile;
    final studentId = _selectedStudentId;
    if (profile == null || studentId == null) return;
    setState(() => _sending = true);
    await giveBehaviorPoint(
      classId: widget.classId,
      studentId: studentId,
      givenBy: profile.id,
      points: value,
    );
    if (!mounted) return;
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final classController = context.watch<ClassController>();
    final rosterController = context.watch<ClassRosterController>();
    final pointsController = context.watch<RealtimeListController<BehaviorPoint>>();
    final classRow = classController.classRow;

    if (classController.loading || classRow == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final studentNames = {
      for (final entry in rosterController.roster)
        if (entry.profile != null) entry.studentId: entry.profile!.fullName,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(classRow.name),
        actions: [
          TextButton.icon(
            onPressed: () => Share.share(
              '${classRow.name} sınıfına katılmak için ChemClass Öğrenci uygulamasında bu kodu kullan: ${classRow.joinCode}',
            ),
            icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.primary),
            label: Text('Kod: ${classRow.joinCode}', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickActions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final action = _quickActions[index];
                return ElevatedButton.icon(
                  onPressed: () => context.push('/class/${widget.classId}/${action.path}'),
                  icon: Icon(action.icon, size: 18),
                  label: Text(action.label),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Öğrenci Seç'),
          if (rosterController.loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (rosterController.roster.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Bu sınıfa henüz öğrenci katılmadı.', style: TextStyle(color: AppColors.muted)),
            )
          else
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rosterController.roster.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = rosterController.roster[index];
                  final selected = entry.studentId == _selectedStudentId;
                  return ChoiceChip(
                    label: Text(entry.profile?.fullName ?? 'İsimsiz'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedStudentId = entry.studentId),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primaryText : AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          _SectionTitle('Davranış Puanı Ver'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final value in _pointOptions) ...[
                  if (value != _pointOptions.first) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedStudentId == null || _sending) ? null : () => _onGivePoint(value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: value > 0 ? AppColors.positiveBg : AppColors.negativeBg,
                        foregroundColor: AppColors.text,
                        elevation: 0,
                      ),
                      child: Text(value > 0 ? '+$value' : '$value', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Son Hareketler'),
          if (pointsController.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Henüz puan verilmedi.', style: TextStyle(color: AppColors.muted)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final point in pointsController.items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(studentNames[point.studentId] ?? 'Öğrenci'),
                          Text(
                            point.points > 0 ? '+${point.points}' : '${point.points}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: point.points >= 0 ? AppColors.success : AppColors.danger,
                            ),
                          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
