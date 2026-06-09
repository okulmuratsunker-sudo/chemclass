import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/session_provider.dart';
import '../services/supabase_service.dart';
import '../models/score.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  ScoreSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider)!;
      final summary = await SupabaseService.loadScores(session);
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) setState(() => _error = 'Veriler yüklenemedi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kAccent));
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final s = _summary!;

    return RefreshIndicator(
      color: kAccent,
      backgroundColor: kSurface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Puan hero kartı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2B25), Color(0xFF0A1A20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '${s.totalScore}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: kAccent,
                    height: 1,
                  ),
                ),
                Text(
                  'Toplam Puanım',
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    s.totalStudents > 0
                        ? '🏆  ${s.rank}. / ${s.totalStudents} öğrenci'
                        : '🏆  —',
                    style: GoogleFonts.inter(
                        color: kAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // İstatistik satırı
          Row(
            children: [
              _StatBox(
                  label: 'Kazanılan',
                  value: '+${s.positive}',
                  color: kAccent),
              const SizedBox(width: 8),
              _StatBox(
                  label: 'Düşülen',
                  value: '-${s.negative}',
                  color: kRed),
              const SizedBox(width: 8),
              _StatBox(
                  label: 'Sınıf Ort.',
                  value: '${s.classAverage}',
                  color: kGold),
            ],
          ),
          const SizedBox(height: 16),

          // Sınıf sıralaması
          _Card(
            title: '📊 Sınıf Sıralaması',
            child: s.leaderboard.isEmpty
                ? _emptyText('Henüz puan verilmedi.')
                : Column(
                    children: s.leaderboard
                        .map((e) => _LeaderboardRow(entry: e))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Puan geçmişi
          _Card(
            title: '📋 Puan Geçmişim',
            child: s.history.isEmpty
                ? _emptyText('Henüz puan kaydı yok.')
                : Column(
                    children: s.history
                        .map((e) => _HistoryRow(entry: e))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _emptyText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: kTextSecondary, fontSize: 14)),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSurface2),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSurface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(title,
                style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          const Divider(height: 1, color: kSurface2),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rankColor = entry.rank == 1
        ? kGold
        : entry.rank == 2
            ? Colors.grey[400]!
            : entry.rank == 3
                ? const Color(0xFFCD7F32)
                : kTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isMe ? kAccentDim : kSurface2,
        borderRadius: BorderRadius.circular(10),
        border: entry.isMe
            ? Border.all(color: kAccent.withOpacity(0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}.',
              style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w800,
                  color: rankColor,
                  fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              entry.isMe ? '${entry.name} (Sen)' : entry.name,
              style: GoogleFonts.inter(
                color: entry.isMe ? kAccent : kTextPrimary,
                fontWeight: entry.isMe ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${entry.score} puan',
            style: GoogleFonts.inter(
                color: entry.isMe ? kAccent : kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ScoreEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM HH:mm', 'tr_TR');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (entry.isPositive ? kAccent : kRed).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                entry.isPositive ? '+${entry.points}' : '${entry.points}',
                style: GoogleFonts.rajdhani(
                  color: entry.isPositive ? kAccent : kRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.reason.isEmpty ? 'Puan' : entry.reason,
                  style: GoogleFonts.inter(
                      color: kTextPrimary, fontSize: 13),
                ),
                Text(
                  fmt.format(entry.createdAt),
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: kTextSecondary, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.inter(color: kTextSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: kAccent, foregroundColor: kBg),
            child: Text('Tekrar Dene',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
