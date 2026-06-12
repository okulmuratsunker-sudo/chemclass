part of 'app_state.dart';

class AttStatRow {
  final String name;
  final String no;
  final int present;
  final int absent;
  final int excused;
  final int total;

  AttStatRow({
    required this.name,
    required this.no,
    required this.present,
    required this.absent,
    required this.excused,
    required this.total,
  });

  int get attendancePercent => total == 0 ? 0 : (((present + excused) / total) * 100).round();
}

/// Daily attendance tracking - mirrors `renderAttend()` / `setAtt()` /
/// `attMarkAll()` / `saveAttendance()` / `showAttStats()`.
extension AppStateAttendance on AppState {
  /// Ensures [attState] reflects the saved attendance for (className, date),
  /// reloading it if the class or date changed.
  void ensureAttState(String className) {
    if (className.isEmpty) return;
    if (attDate.isEmpty) attDate = todayStr();
    final key = '${className}_$attDate';
    if (attStateKey == key) return;
    attStateKey = key;
    attState = {};
    final saved = data.attendance[key] ?? {};
    for (final s in getByClass(className)) {
      attState[s.id] = saved[s.id] ?? '';
    }
  }

  void setAttDate(String date) {
    attDate = date;
    attStateKey = ''; // force reload on next ensureAttState
    notify();
  }

  void setAtt(String id, String val) {
    attState[id] = attState[id] == val ? '' : val;
    notify();
  }

  void attMarkAll(String className, String val) {
    if (className.isEmpty) return;
    for (final s in getByClass(className)) {
      attState[s.id] = val;
    }
    notify();
  }

  /// Returns an error message, or `null` on success.
  String? saveAttendance(String className) {
    if (className.isEmpty) return 'Sınıf seçin';
    if (attDate.isEmpty) return 'Tarih seçin';
    final key = '${className}_$attDate';
    final snap = <String, String>{};
    for (final s in getByClass(className)) {
      snap[s.id] = attState[s.id] ?? '';
    }
    data.attendance[key] = snap;
    save();
    return null;
  }

  Map<String, int> attCounts(String className) {
    final ss = getByClass(className);
    var p = 0, a = 0, e = 0, x = 0;
    for (final s in ss) {
      switch (attState[s.id] ?? '') {
        case 'P':
          p++;
          break;
        case 'A':
          a++;
          break;
        case 'E':
          e++;
          break;
        default:
          x++;
      }
    }
    return {'P': p, 'A': a, 'E': e, 'x': x};
  }

  /// Returns `(rows, fromDate, toDate)`, or `null` if there's no history,
  /// or an error string if the class has no students.
  ({List<AttStatRow> rows, String from, String to})? attStats(String className) {
    final ss = getByClass(className);
    if (ss.isEmpty) return null;
    final prefix = '${className}_';
    final keys = data.attendance.keys.where((k) => k.startsWith(prefix)).toList()..sort();
    if (keys.isEmpty) return (rows: <AttStatRow>[], from: '', to: '');

    final rows = ss.map((s) {
      var p = 0, a = 0, e = 0;
      for (final k in keys) {
        final v = data.attendance[k]?[s.id];
        if (v == 'P') {
          p++;
        } else if (v == 'A') {
          a++;
        } else if (v == 'E') {
          e++;
        }
      }
      return AttStatRow(name: s.name, no: s.no, present: p, absent: a, excused: e, total: keys.length);
    }).toList();

    return (
      rows: rows,
      from: keys.first.split('_').last,
      to: keys.last.split('_').last,
    );
  }
}
