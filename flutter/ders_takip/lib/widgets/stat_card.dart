import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single dashboard statistic card, mirroring `ders-takip.html`'s `sc()`
/// (`.stat-card` / `.stat-label` / `.stat-val` / `.stat-sub`).
class StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.s1,
        border: Border.all(color: dt.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dt.text3, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w500, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: dt.text3), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
