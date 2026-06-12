import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'assignments_screen.dart';
import 'attendance_screen.dart';
import 'behaviour_screen.dart';
import 'board_screen.dart';
import 'board_share_screen.dart';
import 'cloud_screen.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'pick_screen.dart';
import 'students_screen.dart';
import 'timer_screen.dart';

/// Top-level app shell: top bar, fixed nav (Ana Ekran / Bulut / Tahta Modu)
/// and hamburger drawer with the remaining sections, mirroring `index.html`'s
/// `.top`, `.nav-fixed` and `.menu-overlay`.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
            children: [
              TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
              TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
              TextSpan(
                text: '  v18',
                style: TextStyle(color: cc.text2, fontSize: 11, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: app.themeMode == ThemeMode.dark ? 'Açık tema' : 'Koyu tema',
            onPressed: app.toggleTheme,
            icon: Text(app.themeMode == ThemeMode.dark ? '☀️' : '🌙', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      endDrawer: const _MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _Pill(text: tabLabels[app.currentTab] ?? '', color: cc.text2),
                const SizedBox(width: 8),
                _Pill(text: app.cloudStatusText, color: cc.text2),
              ],
            ),
          ),
          const _NavFixed(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: _buildBody(app.currentTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.cloud:
        return const CloudScreen();
      case AppTab.boardShare:
        return const BoardShareScreen();
      case AppTab.pick:
        return const PickScreen();
      case AppTab.timer:
        return const TimerScreen();
      case AppTab.students:
        return const StudentsScreen();
      case AppTab.attend:
        return const AttendanceScreen();
      case AppTab.beh:
        return const BehaviourScreen();
      case AppTab.groups:
        return const GroupsScreen();
      case AppTab.board:
        return const BoardScreen();
      case AppTab.assignments:
        return const AssignmentsScreen();
      case AppTab.messages:
        return const MessagesScreen();
    }
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cc.s2,
        border: Border.all(color: cc.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _NavFixed extends StatelessWidget {
  const _NavFixed();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).cc.border)),
      ),
      child: Row(
        children: [
          Expanded(child: _NavButton(tab: AppTab.home, label: '🏠 Ana Ekran')),
          const SizedBox(width: 6),
          Expanded(child: _NavButton(tab: AppTab.cloud, label: '☁️ Bulut')),
          const SizedBox(width: 6),
          Expanded(child: _NavButton(tab: AppTab.boardShare, label: '🖥️ Tahta Modu')),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AppTab tab;
  final String label;
  const _NavButton({required this.tab, required this.label});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final on = app.currentTab == tab;
    return ElevatedButton(
      onPressed: () => app.setTab(tab),
      style: ElevatedButton.styleFrom(
        backgroundColor: on ? cc.green : cc.s2,
        foregroundColor: on ? const Color(0xFF071018) : cc.text1,
        side: on ? null : BorderSide(color: cc.border),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      child: Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  const _MainDrawer();

  static const _items = [
    AppTab.pick,
    AppTab.timer,
    AppTab.students,
    AppTab.attend,
    AppTab.beh,
    AppTab.groups,
    AppTab.board,
    AppTab.assignments,
    AppTab.messages,
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
                        children: [
                          TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
                          TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: cc.red),
                    child: const Text('✕ Kapat'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _items.map((tab) {
                  final on = app.currentTab == tab;
                  return ListTile(
                    title: Text(
                      tabMenuLabels[tab] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: on ? cc.green : cc.text1,
                      ),
                    ),
                    tileColor: on ? cc.s2 : null,
                    shape: const RoundedRectangleBorder(),
                    onTap: () {
                      app.setTab(tab);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final path = await app.exportBackup();
                        if (context.mounted) {
                          Navigator.pop(context);
                          app.toast('Yedek kaydedildi: $path');
                        }
                      },
                      child: const Text('💾 Yedek Al'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await app.pickAndImportBackup();
                      },
                      child: const Text('📂 Yedek Yükle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
