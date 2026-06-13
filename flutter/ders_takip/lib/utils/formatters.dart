// Ports of `ders-takip.html`'s formatting helpers (`fmt`, `fmtS`, `fmtDur`,
// `fmtDate`, `localDate`, `thisMonth`, `monthLabel`).

const List<String> monthAbbreviations = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

const List<String> monthNamesTr = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _grouped(String digits) {
  final buf = StringBuffer();
  final len = digits.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// `1234.5` -> `"1.234,50 ₺"`.
String fmt(num? n) {
  final v = (n ?? 0).toDouble();
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  return '${_grouped(parts[0])},${parts[1]} ₺';
}

/// Short form: `1234.5` -> `"1,2K ₺"`, `850` -> `"850 ₺"`.
String fmtS(num? n) {
  final v = (n ?? 0).toDouble();
  if (v >= 1000) {
    final k = v / 1000;
    var s = k.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    s = s.replaceAll('.', ',');
    return '${s}K ₺';
  }
  return '${_grouped(v.round().toString())} ₺';
}

/// `1.5` -> `"1sa 30dk"`, `2` -> `"2 sa"`.
String fmtDur(num? n) {
  final v = (n ?? 0).toDouble();
  final h = v.floor();
  final m = ((v - h) * 60).round();
  return m != 0 ? '${h}sa ${m}dk' : '$h sa';
}

/// `"2025-03-07"` -> `"07.03.2025"`.
String fmtDate(String? s) {
  if (s == null || s.isEmpty) return '';
  final p = s.substring(0, 10).split('-');
  if (p.length != 3) return s;
  return '${p[2]}.${p[1]}.${p[0]}';
}

/// Today's date as `"YYYY-MM-DD"`.
String localDate([DateTime? d]) {
  d ??= DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// This month as `"YYYY-MM"`.
String thisMonth([DateTime? d]) {
  d ??= DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}

/// `"2025-03"` -> `"Mar 25"`.
String monthLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  final y = parts[0];
  final m = int.tryParse(parts[1]) ?? 1;
  final abbr = monthAbbreviations[(m - 1).clamp(0, 11)];
  return '$abbr ${y.length >= 2 ? y.substring(y.length - 2) : y}';
}

/// Today's date as `"13 Haziran 2026"`, mirroring
/// `toLocaleDateString('tr-TR',{day:'2-digit',month:'long',year:'numeric'})`.
String todayLong([DateTime? d]) {
  d ??= DateTime.now();
  return '${d.day} ${monthNamesTr[(d.month - 1).clamp(0, 11)]} ${d.year}';
}
