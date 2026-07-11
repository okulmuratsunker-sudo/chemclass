import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/constants.dart';
import 'assignments_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'score_screen.dart';

/// Top-level app shell: top bar + bottom navigation (Ana Sayfa / Puanım /
/// Ödevler / Mesajlar).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _tabs = [AppTab.home, AppTab.score, AppTab.assignments, AppTab.messages];

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
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: app.themeMode == ThemeMode.dark ? 'Açık tema' : 'Koyu tema',
            onPressed: app.toggleTheme,
            icon: Text(app.themeMode == ThemeMode.dark ? '☀️' : '🌙', style: const TextStyle(fontSize: 18)),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: () async {
              final ok = await confirmDialog(context, 'Çıkış Yap', 'Hesabından çıkmak istediğine emin misin?');
              if (ok) await app.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(app.currentTab),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabs.indexOf(app.currentTab),
        onTap: (i) => app.setTab(_tabs[i]),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Text(tabLabels[tab]!.split(' ').first, style: const TextStyle(fontSize: 18)),
              label: tabLabels[tab]!.split(' ').skip(1).join(' '),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.score:
        return const ScoreScreen();
      case AppTab.assignments:
        return const AssignmentsScreen();
      case AppTab.messages:
        return const MessagesScreen();
    }
  }
}
