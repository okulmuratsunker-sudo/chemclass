import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mirrors `chips()`: a wrap of class-filter chips, optionally preceded by
/// an "all classes" chip (empty-string value).
class ClassChips extends StatelessWidget {
  final List<String> classes;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool allowAll;
  final String allLabel;

  const ClassChips({
    super.key,
    required this.classes,
    required this.selected,
    required this.onSelected,
    this.allowAll = false,
    this.allLabel = 'Tüm',
  });

  @override
  Widget build(BuildContext context) {
    final cc = Theme.of(context).cc;
    final items = allowAll ? ['', ...classes] : classes;
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((c) {
        final isSel = selected == c;
        return ChoiceChip(
          label: Text(c.isEmpty ? allLabel : c),
          selected: isSel,
          onSelected: (_) => onSelected(c),
          selectedColor: cc.green,
          labelStyle: TextStyle(
            color: isSel ? const Color(0xFF071018) : cc.text1,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          backgroundColor: cc.s2,
          side: BorderSide(color: cc.border),
        );
      }).toList(),
    );
  }
}
