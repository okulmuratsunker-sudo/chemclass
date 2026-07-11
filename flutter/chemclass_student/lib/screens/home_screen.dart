import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'schedule_screen.dart';

/// Ana Sayfa — greeting, score summary and today's "Ders Programı"
/// (personal class schedule). No web-app equivalent.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final session = app.session;
    final today = app.todaySchedule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cc.green.withValues(alpha: 0.18), cc.orange.withValues(alpha: 0.10)],
              ),
              border: Border.all(color: cc.border),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merhaba, ${session?.studentName ?? ''} 👋',
                    style: TextStyle(color: cc.text1, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text('${session?.className ?? ''} sınıfı', style: TextStyle(color: cc.text2, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Puanım', value: '${session?.score ?? 0}', color: cc.green)),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: 'Sıralama',
                  value: app.myRank != null ? '${app.myRank}. / ${app.leaderboard.length}' : '—',
                  color: cc.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('📅 Bugünün Ders Programı',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  Text(weekDays[(DateTime.now().weekday - 1) % 7], style: TextStyle(color: cc.text2, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (today.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Bugün için ders programına bir şey eklemedin.', style: TextStyle(color: cc.text2)),
                    )
                  else
                    for (final e in today)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cc.s2,
                          border: Border.all(color: cc.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 28,
                              decoration: BoxDecoration(color: avatarFg[e.color.clamp(0, avatarFg.length - 1)], borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 90,
                              child: Text('${e.startTime} - ${e.endTime}', style: TextStyle(color: cc.text2, fontSize: 12)),
                            ),
                            Expanded(
                              child: Text(e.subject, style: TextStyle(color: cc.text1, fontWeight: FontWeight.bold)),
                            ),
                            if (e.room.isNotEmpty) Text(e.room, style: TextStyle(color: cc.text2, fontSize: 12)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cc.s1.withValues(alpha: 0.75),
        border: Border.all(color: cc.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cc.text2, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
