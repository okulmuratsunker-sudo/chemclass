import 'dart:math';

final _rand = Random();

/// Mirrors the web app's `uid()`: Date.now().toString(36) + random suffix.
String uid() {
  final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final suffix = List.generate(6, (_) => _rand.nextInt(36).toRadixString(36)).join();
  return '$time$suffix';
}

/// Turkish locale-aware lowercasing for search comparisons.
String trLower(String s) {
  return s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
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
