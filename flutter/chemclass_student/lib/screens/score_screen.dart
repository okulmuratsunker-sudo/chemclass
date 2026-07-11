import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_entry.dart';
import '../models/leaderboard_entry.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/score_text.dart';

/// Puanım — current score, class ranking and recent score history (mirrors
/// the teacher app's "Liderlik Tablosu" + per-student history, from the
/// student's point of view).
class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final session = app.session;
    final history = (app.studentInfo?.history ?? []).toList()
      ..sort((a, b) => (b.time ?? DateTime(0)).compareTo(a.time ?? DateTime(0)));

    return RefreshIndicator(
      onRefresh: app.refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text('🏆 Puanım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cc.text1)),
                  const SizedBox(height: 8),
                  ScoreText(score: session?.score ?? 0, fontSize: 48),
                  const SizedBox(height: 6),
                  Text(
                    app.myRank != null ? 'Sınıfında ${app.myRank}. sıradasın (${app.leaderboard.length} kişi)' : '',
                    style: TextStyle(color: cc.text2, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('📊 Sınıf Sıralaması — ${session?.className ?? ''}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cc.text1)),
                  const SizedBox(height: 10),
                  if (app.leaderboard.isEmpty)
                    Text('Henüz veri yok.', style: TextStyle(color: cc.text2))
                  else
                    for (var i = 0; i < app.leaderboard.length; i++) ...[
                      _LeaderboardRow(
                        rank: i + 1,
                        entry: app.leaderboard[i],
                        isMe: app.leaderboard[i].id == session?.studentId,
                      ),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('📜 Puan Geçmişi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cc.text1)),
                  const SizedBox(height: 10),
                  if (history.isEmpty)
                    Text('Henüz puan hareketi yok.', style: TextStyle(color: cc.text2))
                  else
                    for (final h in history) _HistoryRow(entry: h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  const _LeaderboardRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? cc.green.withValues(alpha: 0.12) : cc.s2,
        border: Border.all(color: isMe ? cc.green.withValues(alpha: 0.4) : cc.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', style: TextStyle(color: cc.text2, fontWeight: FontWeight.bold))),
          InitialAvatar(name: entry.name, color: entry.color, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${entry.name} (Sen)' : entry.name,
              style: TextStyle(color: cc.text1, fontWeight: isMe ? FontWeight.w900 : FontWeight.bold),
            ),
          ),
          ScoreText(score: entry.score, fontSize: 16),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final t = entry.time;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.n.isNotEmpty ? entry.n : 'Puan güncellendi', style: TextStyle(color: cc.text1)),
                if (t != null) Text(trDateTime(t), style: TextStyle(color: cc.text2, fontSize: 11)),
              ],
            ),
          ),
          ScoreText(score: entry.d, fontSize: 16),
        ],
      ),
    );
  }
}
