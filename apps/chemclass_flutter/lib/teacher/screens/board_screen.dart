import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/board_repository.dart';
import '../../data/classes_repository.dart';
import '../../data/models.dart';

const _tahtaUrl = 'https://tahta.chemclass.app';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BoardController(classId)),
        ChangeNotifierProvider(create: (_) => ClassRosterController(classId)),
      ],
      child: const _BoardView(),
    );
  }
}

class _BoardView extends StatefulWidget {
  const _BoardView();

  @override
  State<_BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<_BoardView> {
  final _minutesController = TextEditingController(text: '5');
  final _groupCountController = TextEditingController(text: '4');

  @override
  void dispose() {
    _minutesController.dispose();
    _groupCountController.dispose();
    super.dispose();
  }

  Future<void> _onShareLink(BoardSession session) async {
    await Share.share('ChemClass Tahtası: $_tahtaUrl\nSınıf kodu: ${session.code}');
  }

  Future<void> _onStartCountdown(BoardController controller) async {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final total = max(1, minutes) * 60;
    final endsAt = DateTime.now().add(Duration(seconds: total)).toIso8601String();
    await controller.updateState('countdown', {'durationSeconds': total, 'endsAt': endsAt});
  }

  Future<void> _onStopCountdown(BoardController controller) async {
    await controller.updateState('idle', {});
  }

  Future<void> _onSelectStudent(BoardController controller, String studentId, String studentName) async {
    await controller.updateState('student', {'studentId': studentId, 'studentName': studentName});
  }

  Future<void> _onSelectRandomStudent(BoardController controller, List<ClassRosterEntry> roster) async {
    if (roster.isEmpty) return;
    final pick = roster[Random().nextInt(roster.length)];
    await _onSelectStudent(controller, pick.studentId, pick.profile?.fullName ?? 'Öğrenci');
  }

  Future<void> _onCreateGroups(BoardController controller, List<ClassRosterEntry> roster) async {
    final count = max(1, int.tryParse(_groupCountController.text) ?? 1);
    final shuffled = [...roster]..shuffle();
    final groups = List.generate(count, (i) => {'name': 'Grup ${i + 1}', 'members': <String>[]});
    for (var i = 0; i < shuffled.length; i++) {
      final members = groups[i % count]['members'] as List<String>;
      members.add(shuffled[i].profile?.fullName ?? 'Öğrenci');
    }
    await controller.updateState('groups', {'groups': groups});
  }

  Future<void> _onClear(BoardController controller) async {
    await controller.updateState('idle', {});
  }

  @override
  Widget build(BuildContext context) {
    final boardController = context.watch<BoardController>();
    final rosterController = context.watch<ClassRosterController>();
    final session = boardController.session;

    if (boardController.loading || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tahta')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final state = boardController.state;
    final roster = rosterController.roster;

    return Scaffold(
      appBar: AppBar(title: const Text('Tahta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text('Tahta Kodu', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                Text(
                  session.code,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 4, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _onShareLink(session),
                  child: const Text('Linki Paylaş'),
                ),
                if (state != null) ...[
                  const SizedBox(height: 8),
                  Text('Tahtada şu an: ${state.stateType}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Geri Sayım',
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('dakika', style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                ElevatedButton(onPressed: () => _onStartCountdown(boardController), child: const Text('Başlat')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => _onStopCountdown(boardController), child: const Text('Durdur')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Öğrenci Seç',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _onSelectRandomStudent(boardController, roster),
                  child: const Text('Rastgele Öğrenci Seç'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in roster)
                      ActionChip(
                        label: Text(entry.profile?.fullName ?? 'İsimsiz'),
                        onPressed: () => _onSelectStudent(boardController, entry.studentId, entry.profile?.fullName ?? 'Öğrenci'),
                        backgroundColor: AppColors.chipBg,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Grup Oluştur',
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _groupCountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('grup', style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                ElevatedButton(onPressed: () => _onCreateGroups(boardController, roster), child: const Text('Oluştur')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => _onClear(boardController), child: const Text('Tahtayı Temizle')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
