import 'dart:math';

final _rand = Random();

/// Mirrors the web app's `uid()`: Date.now().toString(36) + random suffix.
String uid() {
  final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final suffix = List.generate(6, (_) => _rand.nextInt(36).toRadixString(36)).join();
  return '$time$suffix';
}

/// yyyy-MM-dd for "today" (local time), mirrors `todayStr()`.
String todayStr([DateTime? d]) {
  final now = d ?? DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// mm:ss for a duration in seconds, mirrors `fmtTime()`.
String fmtTime(int seconds) {
  final s = max(0, seconds);
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

/// Default label for a score delta, mirrors `pointText()`.
String pointText(int d, [String? label]) {
  if (label != null && label.isNotEmpty) return label;
  switch (d) {
    case 1:
      return 'Katılım';
    case 2:
      return 'Doğru cevap';
    case 3:
      return 'Grup liderliği';
    case -1:
      return 'Uyarı';
    default:
      return d > 0 ? 'Puan eklendi' : 'Puan düşürüldü';
  }
}

/// 6-character class join code, mirrors `genClassCode()`.
String genClassCode() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return List.generate(6, (_) => chars[_rand.nextInt(chars.length)]).join();
}

/// 6-digit board pairing code, mirrors `randomBoardCode()`.
String randomBoardCode() {
  return (100000 + _rand.nextInt(900000)).toString();
}

/// Turkish locale-aware lowercasing for search comparisons.
String trLower(String s) {
  return s
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase();
}

/// Turkish date/time formatting close to `toLocaleString('tr-TR')`.
String trDateTime(DateTime d) {
  final local = d.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}

String trDate(DateTime d) {
  final local = d.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  return '$day.$month.$year';
}

String trTime(DateTime d) {
  final local = d.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
