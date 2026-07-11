import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/confirm.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'sessions_screen.dart';
import 'students_screen.dart';

/// Top-level app shell: header (logo, theme toggle, sign-out), offline
/// banner and bottom navigation across the 4 pages, mirroring
/// `ders-takip.html`'s `<header class="header">` and `#offlineBanner`.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: dt.text1),
            children: [
              const TextSpan(text: 'Ders'),
              TextSpan(text: 'Takip', style: TextStyle(color: dt.green)),
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
            tooltip: 'Çıkış',
            onPressed: () => _signOut(context, app),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (app.offline) _OfflineBanner(queueLength: app.queueLength),
          Expanded(child: _buildBody(app.currentPage)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: DtPage.values.indexOf(app.currentPage),
        onDestinationSelected: (i) => app.setPage(DtPage.values[i]),
        destinations: DtPage.values
            .map((p) => NavigationDestination(
                  icon: Text(dtPageLabels[p]!.split(' ').first),
                  label: dtPageLabels[p]!.split(' ').skip(1).join(' '),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBody(DtPage page) {
    switch (page) {
      case DtPage.dashboard:
        return const DashboardScreen();
      case DtPage.students:
        return const StudentsScreen();
      case DtPage.sessions:
        return const SessionsScreen();
      case DtPage.reports:
        return const ReportsScreen();
    }
  }

  Future<void> _signOut(BuildContext context, AppState app) async {
    final ok = await confirmDialog(context, 'Çıkış', 'Çıkış yapmak istiyor musunuz?', confirmLabel: 'Çıkış');
    if (ok) await app.signOut();
  }
}

class _OfflineBanner extends StatelessWidget {
  final int queueLength;
  const _OfflineBanner({required this.queueLength});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: dt.red,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          const Text(
            '📴 Çevrimdışı — değişiklikler yerel kaydediliyor',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (queueLength > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$queueLength', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
