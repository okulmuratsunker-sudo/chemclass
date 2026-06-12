import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

/// Tahta (board) viewer - mirrors `tahta.html`: PIN entry, then a live board
/// display with 4 views (list/pick/groups/timer), polling the host every 2s.
class BoardViewScreen extends StatefulWidget {
  final String? initialCode;
  const BoardViewScreen({super.key, this.initialCode});

  @override
  State<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends State<BoardViewScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeCtrl.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    final app = context.read<AppState>();
    if (app.boardViewerConnected) app.disconnectBoard();
    super.dispose();
  }

  void _connect() {
    context.read<AppState>().connectBoard(_codeCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    if (!app.boardViewerConnected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tahta Modu')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 28),
                    children: [
                      TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
                      TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Akıllı Tahta', style: TextStyle(color: cc.text2, fontSize: 16)),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 8),
                  decoration: const InputDecoration(hintText: '------', counterText: ''),
                  onSubmitted: (_) => _connect(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _connect, child: const Text('🖥️ Bağlan')),
                ),
                if (app.boardViewerError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(app.boardViewerError, style: TextStyle(color: cc.red)),
                ],
                const SizedBox(height: 16),
                Text(
                  'Kodu öğretmenin telefonundaki Tahta Modu ekranından alın.',
                  style: TextStyle(color: cc.text2, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = app.boardViewerData ?? <String, dynamic>{};
    final view = app.boardViewerManualView;

    return Scaffold(
      appBar: AppBar(
        title: Text(d['className']?.toString() ?? 'Sınıf', overflow: TextOverflow.ellipsis),
        actions: [
          _Pill(text: '#${app.boardViewerCode}'),
          const SizedBox(width: 6),
          _Pill(
            text: app.boardViewerError.isNotEmpty
                ? app.boardViewerError
                : (app.boardViewerUpdatedAt != null ? 'Güncel: ${trTime(app.boardViewerUpdatedAt!)}' : 'Bekleniyor'),
          ),
          IconButton(onPressed: app.disconnectBoard, icon: const Icon(Icons.close), tooltip: 'Çık'),
        ],
      ),
      body: Column(
        children: [
          _BoardNav(app: app),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: switch (view) {
                'pick' => _PickView(app: app, data: d),
                'groups' => _GroupsView(data: d),
                'timer' => _TimerView(app: app, data: d),
                _ => _ListBoardView(data: d),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cc.s2, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: cc.text2, fontSize: 12)),
    );
  }
}

class _BoardNav extends StatelessWidget {
  final AppState app;
  const _BoardNav({required this.app});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    const items = [
      ('list', '📊 Liderlik'),
      ('pick', '🎲 Seçici'),
      ('groups', '👥 Gruplar'),
      ('timer', '⏱️ Sayaç'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cc.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (v, label) in items)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(label),
                  selected: app.boardViewerManualView == v,
                  onSelected: (_) => app.setBoardViewerView(v),
                  selectedColor: cc.green,
                  labelStyle: TextStyle(
                    color: app.boardViewerManualView == v ? const Color(0xFF071018) : cc.text1,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  backgroundColor: cc.s2,
                  side: BorderSide(color: cc.border),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListBoardView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ListBoardView({required this.data});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final students = (data['students'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList()
      ..sort((a, b) => ((b['score'] as num?) ?? 0).compareTo((a['score'] as num?) ?? 0));
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text('Öğrenci bulunamadı.', style: TextStyle(color: cc.text2))),
      );
    }
    final mx = students.fold<int>(1, (m, s) => max(m, ((s['score'] as num?) ?? 0).abs().toInt()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < students.length; i++) _ListBoardRow(rank: i + 1, student: students[i], maxScore: mx),
      ],
    );
  }
}

class _ListBoardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> student;
  final int maxScore;
  const _ListBoardRow({required this.rank, required this.student, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final score = ((student['score'] as num?) ?? 0).toInt();
    final colorIdx = (student['color'] is num) ? (student['color'] as num).toInt() : 0;
    final c = colorIdx.clamp(0, avatarFg.length - 1);
    final name = student['name']?.toString() ?? '?';
    final no = student['no']?.toString() ?? '';
    final className = student['className']?.toString() ?? '';
    final barValue = max(0.04, score.abs() / maxScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#$rank', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: cc.text2))),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: avatarBg[c], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: avatarFg[c], fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: cc.text1)),
                Text('$className${no.isNotEmpty ? ' · No: $no' : ''}', style: TextStyle(color: cc.text2, fontSize: 12)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: barValue, minHeight: 5, backgroundColor: cc.s1, color: cc.green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${score > 0 ? '+' : ''}$score',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: score < 0 ? cc.red : cc.green)),
        ],
      ),
    );
  }
}

class _PickView extends StatelessWidget {
  final AppState app;
  final Map<String, dynamic> data;
  const _PickView({required this.app, required this.data});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final recent = (data['recent'] as List? ?? []).map((e) => e.toString()).toList();

    String name = '?';
    String info = '';
    String scoreText = '';
    Color scoreColor = cc.green;
    int? colorIdx;

    if (app.boardViewerSpinning) {
      name = app.boardViewerSpinName;
    } else {
      final pick = app.boardViewerPickResult;
      if (pick != null) {
        name = pick['name']?.toString() ?? '?';
        final no = pick['no']?.toString() ?? '';
        if (no.isNotEmpty) info = 'No: $no';
        final score = ((pick['score'] as num?) ?? 0).toInt();
        scoreText = '${score > 0 ? '+' : ''}$score';
        scoreColor = score < 0 ? cc.red : cc.green;
        colorIdx = pick['color'] is num ? (pick['color'] as num).toInt() : 0;
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: cc.s2,
            border: Border.all(color: app.boardViewerSpinning ? cc.green : cc.border, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (colorIdx != null) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: avatarBg[colorIdx.clamp(0, avatarFg.length - 1)], shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: avatarFg[colorIdx.clamp(0, avatarFg.length - 1)], fontWeight: FontWeight.w900, fontSize: 36)),
                ),
                const SizedBox(height: 14),
              ],
              Text(name, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: cc.text1), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (info.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(right: 16), child: Text(info, style: TextStyle(color: cc.text2, fontSize: 18))),
                  if (scoreText.isNotEmpty)
                    Text(scoreText, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: scoreColor)),
                ],
              ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Son seçilenler: ${recent.join(' · ')}', style: TextStyle(color: cc.text2, fontSize: 13), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _GroupsView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _GroupsView({required this.data});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final groups = (data['groups'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text('Henüz grup oluşturulmadı.', style: TextStyle(color: cc.text2))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in groups)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cc.s2, border: Border.all(color: cc.border), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(g['name']?.toString() ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: cc.text1))),
                    if (g['score'] != null)
                      Builder(builder: (context) {
                        final score = (g['score'] as num).toInt();
                        return Text('${score > 0 ? '+' : ''}$score',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: score < 0 ? cc.red : cc.green));
                      }),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in (g['members'] as List? ?? []))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: cc.s1, borderRadius: BorderRadius.circular(16)),
                        child: Text(m.toString(), style: TextStyle(fontSize: 13, color: cc.text2)),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimerView extends StatefulWidget {
  final AppState app;
  final Map<String, dynamic> data;
  const _TimerView({required this.app, required this.data});

  @override
  State<_TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<_TimerView> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.app.boardViewerTimerRunning && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final remaining = widget.app.boardViewerTimerRemaining;
    final running = widget.app.boardViewerTimerRunning;
    final total = (widget.data['timerTotal'] as num?)?.toInt() ?? 0;
    final hasTimer = widget.data['timerEnd'] != null || widget.data['timerRemaining'] != null;

    String status;
    if (!hasTimer) {
      status = 'Bekleniyor';
    } else if (running) {
      status = '▶ Çalışıyor';
    } else if (remaining > 0) {
      status = '⏸ Duraklatıldı';
    } else if (widget.data['timerEnd'] != null) {
      status = '⏰ Süre bitti!';
    } else {
      status = '⏹ Durduruldu';
    }

    final danger = running && remaining > 0 && remaining <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasTimer ? fmtTime(remaining) : '--:--',
            style: TextStyle(fontSize: 96, fontWeight: FontWeight.w900, letterSpacing: -4, color: danger ? cc.red : cc.text1),
          ),
          const SizedBox(height: 10),
          Text(status, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cc.text2)),
          if (total > 0) ...[
            const SizedBox(height: 6),
            Text('Toplam: ${fmtTime(total)}', style: TextStyle(color: cc.text2, fontSize: 16)),
          ],
        ],
      ),
    );
  }
}
