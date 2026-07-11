import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/snack.dart';
import '../widgets/class_chips.dart';
import '../widgets/score_action_button.dart';

/// Rastgele Seçici - mirrors `index.html`'s `#pick` section.
class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final cls = app.selectedPickClass;
    final lastPicked = app.lastPickedStudent;

    String bigName;
    String bigInfo;
    if (app.isSpinning) {
      bigName = app.spinName;
      bigInfo = '';
    } else if (app.pickResultName == '?') {
      bigName = '?';
      bigInfo = cls.isEmpty ? 'Önce sınıf seçin' : 'Seçim yapılacak';
    } else {
      bigName = app.pickResultName;
      bigInfo = app.pickResultInfo;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassChips(
              classes: app.data.classes,
              selected: cls,
              onSelected: (c) {
                app.selectedPickClass = c;
                app.resetPick();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: app.isSpinning
                        ? null
                        : () async {
                            final info = await app.pickStudent(cls);
                            if (info != null && context.mounted) showSnack(context, info);
                          },
                    child: const Text('🎲 Rastgele Seç'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: app.resetPick, child: const Text('↺ Sıfırla')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cc.s2,
                border: Border.all(color: app.isSpinning ? cc.orange : cc.border, width: 2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(bigName,
                      style: TextStyle(fontSize: 34, color: cc.green, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center),
                  if (bigInfo.isNotEmpty) const SizedBox(height: 6),
                  if (bigInfo.isNotEmpty)
                    Text(bigInfo, style: TextStyle(color: cc.text2), textAlign: TextAlign.center),
                ],
              ),
            ),
            if (lastPicked != null && !app.isSpinning) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ScoreActionButton(
                    label: '−1 Uyarı',
                    color: cc.red,
                    onTap: () => app.changeScore(lastPicked.id, -1, label: 'Uyarı'),
                  ),
                  ScoreActionButton(
                    label: '+1 Katılım',
                    color: cc.green,
                    onTap: () => app.changeScore(lastPicked.id, 1, label: 'Katılım'),
                  ),
                  ScoreActionButton(
                    label: '+2 Doğru cevap',
                    color: cc.green,
                    onTap: () => app.changeScore(lastPicked.id, 2, label: 'Doğru cevap'),
                  ),
                  ScoreActionButton(
                    label: '+3 Grup liderliği',
                    color: cc.green,
                    onTap: () => app.changeScore(lastPicked.id, 3, label: 'Grup liderliği'),
                  ),
                  for (final b in app.data.customBtns)
                    ScoreActionButton(
                      label: '${b.val > 0 ? '+' : ''}${b.val} ${b.label}',
                      color: cc.text1,
                      onTap: () => app.changeScore(lastPicked.id, b.val, label: b.label),
                    ),
                  Text('${lastPicked.score}',
                      style: TextStyle(
                        color: lastPicked.score < 0 ? cc.red : cc.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      )),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Son seçilenler: ${app.recentPickedNames.isEmpty ? 'Yok' : app.recentPickedNames.join(', ')}',
              style: TextStyle(color: cc.text2, fontSize: 12),
            ),
            Text('Not: Son 5 seçilen öğrenci geçici olarak tekrar seçilmez.',
                style: TextStyle(color: cc.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
