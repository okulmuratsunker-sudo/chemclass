import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'dialogs/schedule_entry_dialog.dart';

/// Ders Programı — full weekly view/editor for the personal class schedule.
/// Local-only, no web-app equivalent.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final today = (DateTime.now().weekday - 1) % 7;
    _tabController = TabController(length: weekDays.length, vsync: this, initialIndex: today);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Ders Programım'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (final d in weekDays) Tab(text: d)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (var day = 0; day < weekDays.length; day++)
            _DayList(day: day, app: app, cc: cc),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showScheduleEntryDialog(context, app, day: _tabController.index),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  final int day;
  final AppState app;
  final AppColors cc;
  const _DayList({required this.day, required this.app, required this.cc});

  @override
  Widget build(BuildContext context) {
    final entries = app.scheduleForDay(day);
    if (entries.isEmpty) {
      return Center(
        child: Text('${weekDays[day]} için ders eklenmedi.', style: TextStyle(color: cc.text2)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Card(
          child: ListTile(
            leading: Container(
              width: 6,
              decoration: BoxDecoration(color: avatarFg[e.color.clamp(0, avatarFg.length - 1)], borderRadius: BorderRadius.circular(3)),
            ),
            title: Text(e.subject, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text1)),
            subtitle: Text(
              e.room.isEmpty ? '${e.startTime} - ${e.endTime}' : '${e.startTime} - ${e.endTime} • ${e.room}',
              style: TextStyle(color: cc.text2),
            ),
            onTap: () => showScheduleEntryDialog(context, app, day: day, existing: e),
          ),
        );
      },
    );
  }
}
