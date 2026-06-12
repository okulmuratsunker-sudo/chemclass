part of 'app_state.dart';

/// Excel export, JSON backup/restore and CSV/XLSX student import - mirrors
/// `exportToExcel()` / `exportData()` / `importData()` / `readFile()`.
extension AppStateExport on AppState {
  /// Builds a leaderboard .xlsx for [className] (or all students if empty)
  /// and returns the path of the written file, or `null` if there are no
  /// students to export.
  Future<String?> exportToExcel(String className) async {
    final ss = List<Student>.from(getByClass(className.isEmpty ? null : className))
      ..sort((a, b) => b.score.compareTo(a.score));
    if (ss.isEmpty) return null;

    final excel = Excel.createExcel();
    final sheetName = className.isNotEmpty ? className : 'Tum Siniflar';
    final sheet = excel[sheetName];
    sheet.appendRow(<CellValue?>[
      TextCellValue('Sıra'),
      TextCellValue('No'),
      TextCellValue('Ad Soyad'),
      TextCellValue('Sınıf'),
      TextCellValue('Puan'),
    ]);
    for (var i = 0; i < ss.length; i++) {
      final s = ss[i];
      sheet.appendRow(<CellValue?>[
        IntCellValue(i + 1),
        TextCellValue(s.no),
        TextCellValue(s.name),
        TextCellValue(s.className),
        IntCellValue(s.score),
      ]);
    }
    excel.delete('Sheet1');

    final bytes = excel.save();
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final fileName = 'chemclass-${className.isNotEmpty ? className : 'tum'}-${todayStr()}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes the full app data as a JSON backup and returns its path,
  /// mirroring `exportData()`.
  Future<String> exportBackup() async {
    final dir = await getTemporaryDirectory();
    final fileName = 'chemclass-v18-yedek-${todayStr()}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(data.toJson()));
    return file.path;
  }

  /// Restores app data from a JSON backup file, mirroring `importData()`.
  /// Returns an error message, or `null` on success.
  Future<String?> importBackup(String filePath) async {
    try {
      final raw = await File(filePath).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _data = AppData.fromJson(json);
      await save();
      return null;
    } catch (_) {
      return 'Yedek dosyası okunamadı';
    }
  }

  /// Smart-imports students from a CSV or XLSX file into [className],
  /// mirroring `readFile()`. Returns counts of added/duplicate/skipped rows,
  /// or `null` if the file could not be read.
  Future<({int added, int dup, int skipped})?> importStudents(String filePath, String className) async {
    List<List<Object?>> rows;
    try {
      if (filePath.toLowerCase().endsWith('.csv')) {
        final text = await File(filePath).readAsString();
        rows = text.split(RegExp(r'\r?\n')).map<List<Object?>>(splitCsvLine).toList();
      } else {
        final bytes = await File(filePath).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables.isNotEmpty ? excel.tables[excel.tables.keys.first] : null;
        rows = (sheet?.rows ?? []).map((row) => row.map((cell) => cell?.value).toList()).toList();
      }
    } catch (_) {
      return null;
    }

    var added = 0, dup = 0, skipped = 0;
    for (final row in rows) {
      final extracted = extractStudent(row);
      if (extracted == null) {
        skipped++;
        continue;
      }
      final name = extracted.name.replaceAll(RegExp(r'\s+'), ' ').trim();
      final no = extracted.no.trim();
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      final exists = data.students.any((s) =>
          s.className == className &&
          ((no.isNotEmpty && s.no == no) || trLower(s.name) == trLower(name)));
      if (exists) {
        dup++;
        continue;
      }
      data.students.add(Student(id: uid(), className: className, name: name, no: no, score: 0, color: 0));
      added++;
    }
    await save();
    return (added: added, dup: dup, skipped: skipped);
  }
}
