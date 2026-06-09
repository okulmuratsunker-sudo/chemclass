import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/constants.dart';
import '../models/app_data.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String? _sessionCode;
  String? _selectedClass;
  bool _isActive = false;
  Timer? _syncTimer;
  String _boardView = 'list'; // list, pick, groups, timer

  @override
  void dispose() {
    _syncTimer?.cancel();
    if (_sessionCode != null) {
      SupabaseService.closeBoardSession(_sessionCode!);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final data = ref.read(appDataProvider);
    if (data.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Önce sınıf ekleyin.'), backgroundColor: kSurface2),
      );
      return;
    }
    _selectedClass ??= data.classes.first;
    final snapshot = data.toJson();
    final code = await SupabaseService.createBoardSession(
      className: _selectedClass!,
      snapshot: snapshot,
    );
    setState(() {
      _sessionCode = code;
      _isActive = true;
    });
    // Sync every 10 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sync());
  }

  Future<void> _sync() async {
    if (_sessionCode == null) return;
    final snapshot = ref.read(appDataProvider).toJson();
    await SupabaseService.updateBoardSession(_sessionCode!, snapshot);
  }

  Future<void> _endSession() async {
    _syncTimer?.cancel();
    if (_sessionCode != null) {
      await SupabaseService.closeBoardSession(_sessionCode!);
    }
    setState(() {
      _sessionCode = null;
      _isActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);

    if (!_isActive) {
      return _InactiveBoard(
        classes: data.classes,
        selectedClass: _selectedClass,
        onClassChange: (c) => setState(() => _selectedClass = c),
        onStart: _startSession,
      );
    }

    return Column(
      children: [
        // Session header
        Container(
          color: kSurface,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Code + QR
              _SessionCode(code: _sessionCode!),
              const Spacer(),
              // View switcher
              _ViewSwitcher(
                current: _boardView,
                onChanged: (v) => setState(() => _boardView = v),
              ),
              const SizedBox(width: 12),
              // End session
              TextButton.icon(
                icon: const Icon(Icons.stop_circle, size: 18),
                label: const Text('Bitir'),
                style: TextButton.styleFrom(foregroundColor: kRed),
                onPressed: _endSession,
              ),
            ],
          ),
        ),
        // Board content
        Expanded(
          child: _BoardContent(
            view: _boardView,
            data: data,
            selectedClass: _selectedClass ?? data.classes.firstOrNull ?? '',
          ),
        ),
      ],
    );
  }
}

class _InactiveBoard extends StatelessWidget {
  final List<String> classes;
  final String? selectedClass;
  final void Function(String) onClassChange;
  final VoidCallback onStart;
  const _InactiveBoard({
    required this.classes,
    required this.selectedClass,
    required this.onClassChange,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cast, color: kAccent, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            'Tahta Yansıtma',
            style: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Öğrencilerin telefonlarından\nders içeriğini görmesini sağlayın',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (classes.isNotEmpty) ...[
            Text('Sınıf seç:', style: TextStyle(color: kTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: classes.map((c) => GestureDetector(
                onTap: () => onClassChange(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedClass == c ? kAccent : kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selectedClass == c ? kAccent : kSurface2),
                  ),
                  child: Text(c, style: TextStyle(
                    color: selectedClass == c ? kBg : kTextSecondary,
                    fontWeight: selectedClass == c ? FontWeight.w700 : FontWeight.normal,
                  )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: kBg,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.play_circle, size: 24),
            label: const Text('Oturumu Başlat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _SessionCode extends StatelessWidget {
  final String code;
  const _SessionCode({required this.code});

  String get _boardUrl => 'https://chemclass.muratsunker.workers.dev/tahta.html?code=$code';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQr(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: _boardUrl,
              version: QrVersions.auto,
              size: 48,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kod:', style: TextStyle(color: kTextSecondary, fontSize: 11)),
              Row(
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      color: kAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kod kopyalandı'), backgroundColor: kSurface2, duration: const Duration(seconds: 2)),
                      );
                    },
                    child: Icon(Icons.copy, color: kTextSecondary, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('QR Kod', style: TextStyle(color: kTextPrimary), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12))),
              child: QrImageView(data: _boardUrl, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 12),
            Text(
              'Kod: $code',
              style: TextStyle(color: kAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              'Öğrenciler bu kodu girerek\nderse bağlanabilir',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _ViewSwitcher({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(icon: Icons.list, value: 'list', current: current, onChanged: onChanged),
        _Btn(icon: Icons.person_search, value: 'pick', current: current, onChanged: onChanged),
        _Btn(icon: Icons.group, value: 'groups', current: current, onChanged: onChanged),
        _Btn(icon: Icons.timer, value: 'timer', current: current, onChanged: onChanged),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String current;
  final void Function(String) onChanged;
  const _Btn({required this.icon, required this.value, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? kAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: selected ? kAccent : kTextSecondary, size: 20),
      ),
    );
  }
}

class _BoardContent extends StatelessWidget {
  final String view;
  final AppData data;
  final String selectedClass;
  const _BoardContent({required this.view, required this.data, required this.selectedClass});

  @override
  Widget build(BuildContext context) {
    final students = data.studentsOf(selectedClass);
    switch (view) {
      case 'pick':
        return _RandomPicker(students: students);
      case 'groups':
        return _GroupMaker(students: students);
      case 'timer':
        return const _CountdownTimer();
      default:
        // list view: leaderboard
        final sorted = [...students]..sort((a, b) => b.score.compareTo(a.score));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final s = sorted[i];
            final color = kAvatarColors[s.color % kAvatarColors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(s.name[0].toUpperCase(), style: TextStyle(color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.name, style: TextStyle(color: kTextPrimary))),
                  Text('${s.score}', style: TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(' puan', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ],
              ),
            );
          },
        );
    }
  }
}

class _RandomPicker extends StatefulWidget {
  final List<Student> students;
  const _RandomPicker({required this.students});

  @override
  State<_RandomPicker> createState() => _RandomPickerState();
}

class _RandomPickerState extends State<_RandomPicker> with SingleTickerProviderStateMixin {
  Student? _picked;
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _pick() {
    if (widget.students.isEmpty) return;
    final rand = (widget.students..shuffle()).first;
    setState(() => _picked = rand);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = _picked != null ? kAvatarColors[_picked!.color % kAvatarColors.length] : kAccent;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_picked != null)
            ScaleTransition(
              scale: _scale,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      _picked!.name[0].toUpperCase(),
                      style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_picked!.name, style: TextStyle(color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('No: ${_picked!.no}', style: TextStyle(color: kTextSecondary)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: kBg,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.casino),
            label: Text(_picked == null ? 'Öğrenci Seç' : 'Tekrar Seç'),
            onPressed: _pick,
          ),
        ],
      ),
    );
  }
}

class _GroupMaker extends StatefulWidget {
  final List<Student> students;
  const _GroupMaker({required this.students});

  @override
  State<_GroupMaker> createState() => _GroupMakerState();
}

class _GroupMakerState extends State<_GroupMaker> {
  int _groupCount = 4;
  List<List<Student>>? _groups;

  void _makeGroups() {
    final shuffled = [...widget.students]..shuffle();
    final groups = List.generate(_groupCount, (i) => <Student>[]);
    for (var i = 0; i < shuffled.length; i++) {
      groups[i % _groupCount].add(shuffled[i]);
    }
    setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Grup Sayısı:', style: TextStyle(color: kTextSecondary)),
              const SizedBox(width: 12),
              ...List.generate(6, (i) => i + 2).map((n) => GestureDetector(
                onTap: () => setState(() => _groupCount = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _groupCount == n ? kAccent : kSurface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('$n', style: TextStyle(
                    color: _groupCount == n ? kBg : kTextSecondary,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              )),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kBg),
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text('Grupla'),
                onPressed: _makeGroups,
              ),
            ],
          ),
        ),
        if (_groups != null) Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _groupCount <= 3 ? _groupCount : 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _groups!.length,
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kAvatarColors[i % kAvatarColors.length].withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grup ${i + 1}',
                    style: TextStyle(
                      color: kAvatarColors[i % kAvatarColors.length],
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(
                      children: _groups![i].map((s) => Text(
                        '• ${s.name}',
                        style: TextStyle(color: kTextPrimary, fontSize: 12),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) else Expanded(
          child: Center(
            child: Text('Grupları oluşturmak için butona basın.', style: TextStyle(color: kTextSecondary)),
          ),
        ),
      ],
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer();

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  int _totalSeconds = 5 * 60;
  int _remaining = 5 * 60;
  bool _running = false;
  Timer? _timer;

  final _presets = [60, 120, 180, 300, 600, 900];
  final _presetLabels = ['1d', '2d', '3d', '5d', '10d', '15d'];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_remaining == 0) _remaining = _totalSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          _timer?.cancel();
          setState(() => _running = false);
        }
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _remaining = _totalSeconds; _running = false; });
  }

  String get _display {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _remaining / _totalSeconds : 0.0;
    final color = progress > 0.33 ? kAccent : progress > 0.1 ? Colors.orange : kRed;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Presets
          Wrap(
            spacing: 8,
            children: _presets.asMap().entries.map((e) => GestureDetector(
              onTap: () => setState(() { _totalSeconds = e.value; _remaining = e.value; _running = false; _timer?.cancel(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _totalSeconds == e.value ? kAccent.withOpacity(0.2) : kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _totalSeconds == e.value ? kAccent : kSurface2),
                ),
                child: Text(_presetLabels[e.key], style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 40),
          // Circular progress
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  color: color,
                  backgroundColor: kSurface2,
                ),
                Text(_display, style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _running ? Colors.orange : kAccent,
                  foregroundColor: kBg,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Duraklat' : (_remaining == 0 ? 'Yeniden' : 'Başlat')),
                onPressed: _toggle,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kTextSecondary.withOpacity(0.4)),
                  foregroundColor: kTextSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Sıfırla'),
                onPressed: _reset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
