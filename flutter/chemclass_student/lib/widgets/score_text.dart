import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A signed score, green if >= 0, red if < 0.
class ScoreText extends StatelessWidget {
  final int score;
  final double fontSize;
  const ScoreText({super.key, required this.score, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final color = score < 0 ? cc.red : cc.green;
    final sign = score > 0 ? '+' : '';
    return Text('$sign$score', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: fontSize));
  }
}

/// A colored square avatar with the student's initial, used in the
/// leaderboard.
class InitialAvatar extends StatelessWidget {
  final String name;
  final int color;
  final double size;
  const InitialAvatar({super.key, required this.name, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final c = color.clamp(0, avatarFg.length - 1);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: avatarBg[c], borderRadius: BorderRadius.circular(size * 0.25)),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: avatarFg[c], fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}
