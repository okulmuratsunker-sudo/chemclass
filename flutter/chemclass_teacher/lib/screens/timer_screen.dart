import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/snack.dart';

/// Geri Sayım Sayacı - mirrors `index.html`'s `#timer` section.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _secCtrl;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _minCtrl = TextEditingController(text: '${app.timerTotal ~/ 60}');
    _secCtrl = TextEditingController(text: '${app.timerTotal % 60}');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  int get _min => int.tryParse(_minCtrl.text) ?? 0;
  int get _sec => int.tryParse(_secCtrl.text) ?? 0;

  void _applyPreset(int m, int s) {
    final app = context.read<AppState>();
    app.setTimer(m, s);
    setState(() {
      _minCtrl.text = '$m';
      _secCtrl.text = '$s';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text('⏳ Geri Sayım Sayacı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cc.text1)),
            const SizedBox(height: 12),
            Text(
              app.timerDisplay,
              style: TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: app.timerDanger ? cc.red : cc.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: 'Dakika'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _secCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: 'Saniye'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final m in [1, 3, 5, 10, 15])
                  OutlinedButton(
                    onPressed: () => _applyPreset(m, 0),
                    style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                    child: Text('$m dk'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final err = app.startTimer(_min, _sec);
                    if (err != null) showSnack(context, err);
                  },
                  child: const Text('▶ Başlat'),
                ),
                OutlinedButton(onPressed: app.pauseTimer, child: const Text('⏸ Duraklat')),
                OutlinedButton(
                  onPressed: () => app.resetTimer(_min, _sec),
                  style: OutlinedButton.styleFrom(foregroundColor: cc.red, side: BorderSide(color: cc.red.withValues(alpha: 0.4))),
                  child: const Text('↺ Sıfırla'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: cc.border))),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('🔊 Bitiş Sesi', style: TextStyle(color: cc.text2, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final s in TimerSound.values)
                        ChoiceChip(
                          label: Text(s.label),
                          selected: app.sndType == s,
                          onSelected: (_) => app.setSound(s),
                          selectedColor: cc.green,
                          labelStyle: TextStyle(
                            color: app.sndType == s ? const Color(0xFF071018) : cc.text1,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: cc.s2,
                          side: BorderSide(color: cc.border),
                        ),
                      OutlinedButton(onPressed: app.testSound, child: const Text('▶ Test')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Süre bitince ekranda uyarı verir.', style: TextStyle(color: cc.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
