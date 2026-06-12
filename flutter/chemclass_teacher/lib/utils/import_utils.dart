/// CSV/XLSX smart-import heuristics, ported from the web app's
/// `extractStudent` / `looksName` / `looksNo` / `isHeader` / `splitCsvLine`.

class ExtractedStudent {
  final String name;
  final String no;
  ExtractedStudent({required this.name, required this.no});
}

/// Splits a CSV line on `;`, `,` or tab while respecting double-quoted fields.
List<String> splitCsvLine(String line) {
  final out = <String>[];
  var cur = StringBuffer();
  var q = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (q && i + 1 < line.length && line[i + 1] == '"') {
        cur.write('"');
        i++;
      } else {
        q = !q;
      }
    } else if (!q && (ch == ';' || ch == ',' || ch == '\t')) {
      out.add(cur.toString());
      cur = StringBuffer();
    } else {
      cur.write(ch);
    }
  }
  out.add(cur.toString());
  return out;
}

String cleanCell(Object? x) {
  return (x?.toString() ?? '')
      .replaceFirst(RegExp(r'^﻿'), '')
      .replaceFirst(RegExp(r'^"|"$'), '')
      .trim();
}

final RegExp _headerRe = RegExp(
  r'adı soyadı|adi soyadi|okul numarası|okul numarasi|sıra no|sira no|'
  r'ağırlıklı|agirlikli|puanı|puani|muaf|proje|başarılı|basarili|'
  r'öğrenci sayısı|ogrenci sayisi|müdür|mudur|öğretmeni|ogretmeni|'
  r'devamsızlık|devamsizlik|y\d',
  caseSensitive: false,
);

bool isHeader(List<String> vals) {
  final j = vals.join(' ').toLowerCase();
  return _headerRe.hasMatch(j);
}

final RegExp _notNameRe = RegExp(
  r'başarılı|basarili|başarısız|basarisiz|oranı|orani|müdür|mudur|'
  r'öğretmen|ogretmen|devamsız|devamsiz|millî eğitim|milli egitim',
  caseSensitive: false,
);
final RegExp _digitsOnlyRe = RegExp(r'^\d+$');
final RegExp _hasLetterRe = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]');
final RegExp _looksNoRe = RegExp(r'^\d{1,6}$');

bool looksName(Object? raw) {
  final x = cleanCell(raw);
  if (x.isEmpty || x.length < 5) return false;
  if (_digitsOnlyRe.hasMatch(x)) return false;
  if (_notNameRe.hasMatch(x)) return false;
  if (!_hasLetterRe.hasMatch(x)) return false;
  final words = x.replaceAll(RegExp(r'\s+'), ' ').split(' ');
  return words.length >= 2;
}

bool looksNo(Object? raw) {
  final x = cleanCell(raw);
  return _looksNoRe.hasMatch(x);
}

/// Tries to find a (name, schoolNo) pair within a row of raw cell values.
ExtractedStudent? extractStudent(List<Object?> rawVals) {
  final vals = rawVals.map(cleanCell).toList();
  if (isHeader(vals)) return null;
  final wide = vals.length > 4;

  for (var i = 0; i < vals.length - 1; i++) {
    if (looksNo(vals[i]) && looksName(vals[i + 1])) {
      return ExtractedStudent(no: vals[i], name: vals[i + 1]);
    }
    if (i < vals.length - 2 &&
        looksNo(vals[i]) &&
        looksNo(vals[i + 1]) &&
        looksName(vals[i + 2])) {
      return ExtractedStudent(no: vals[i + 1], name: vals[i + 2]);
    }
  }

  if (!wide) {
    if (vals.isNotEmpty && looksName(vals[0])) {
      return ExtractedStudent(
        name: vals[0],
        no: (vals.length > 1 && looksNo(vals[1])) ? vals[1] : '',
      );
    }
    if (vals.length > 1 && looksNo(vals[0]) && looksName(vals[1])) {
      return ExtractedStudent(no: vals[0], name: vals[1]);
    }
  }

  final ni = vals.indexWhere(looksName);
  if (ni >= 0) {
    var no = '';
    for (final k in [ni - 1, ni + 1, 0, 1, 2]) {
      if (k >= 0 && k < vals.length && looksNo(vals[k])) {
        no = vals[k];
        break;
      }
    }
    if (no.isNotEmpty || !wide) {
      return ExtractedStudent(name: vals[ni], no: no);
    }
  }
  return null;
}
