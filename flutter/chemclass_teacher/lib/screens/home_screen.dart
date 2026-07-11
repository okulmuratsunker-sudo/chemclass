import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Ana Ekran - mirrors `index.html`'s `#home` section.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cc = Theme.of(context).cc;
    final totalScore = app.data.students.fold<int>(0, (sum, s) => sum + s.score);

    return Column(
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
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 30),
                  children: [
                    TextSpan(text: 'CHEM', style: TextStyle(color: cc.green)),
                    TextSpan(text: 'CLASS', style: TextStyle(color: cc.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Created by Murat Sünker',
                  style: TextStyle(color: cc.text1, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Katılım, davranış puanı ve sınıf içi etkinlik aracı',
                  style: TextStyle(color: cc.text2, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Stat(label: 'Sınıf', value: '${app.data.classes.length}')),
            const SizedBox(width: 12),
            Expanded(child: _Stat(label: 'Öğrenci', value: '${app.data.students.length}')),
            const SizedBox(width: 12),
            Expanded(child: _Stat(label: 'Toplam Puan', value: '$totalScore')),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _HomeButton(
              title: '🎲 Rastgele Seçici',
              subtitle: 'Sınıfta hızlı öğrenci seç.',
              onTap: () => app.setTab(AppTab.pick),
            ),
            _HomeButton(
              title: '⏳ Geri Sayım Sayacı',
              subtitle: 'Etkinlik, sınav veya grup çalışması için süre başlat.',
              onTap: () => app.setTab(AppTab.timer),
            ),
            _HomeButton(
              title: '🏫 Sınıf ve Öğrenciler',
              subtitle: 'Excel/CSV aktar, düzenle ve yedekle.',
              onTap: () => app.setTab(AppTab.students),
            ),
            _HomeButton(
              title: '📋 Yoklama',
              subtitle: 'Geldi / Gelmedi / Geç hızlı işaretle.',
              onTap: () => app.setTab(AppTab.attend),
            ),
            _HomeButton(
              title: '📊 Liderlik Tablosu',
              subtitle: 'Puanları sınıf sınıf takip et.',
              onTap: () => app.setTab(AppTab.board),
            ),
            _HomeButton(
              title: '🖥️ Tahta Modu',
              subtitle: 'Akıllı tahtaya güvenli görüntüleme kodu oluştur.',
              onTap: () => app.setTab(AppTab.boardShare),
            ),
            _HomeButton(
              title: '📚 Ödevler',
              subtitle: 'Ödev, duyuru ve görev gönder.',
              onTap: () => app.setTab(AppTab.assignments),
            ),
            _HomeButton(
              title: '💬 Mesajlar',
              subtitle: 'Öğrencilerinle birebir veya toplu yazış.',
              onTap: () => app.setTab(AppTab.messages),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

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
          Text(value, style: TextStyle(color: cc.green, fontSize: 26, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HomeButton({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    return Material(
      color: cc.s2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: cc.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: TextStyle(color: cc.text1, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: cc.text2, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
