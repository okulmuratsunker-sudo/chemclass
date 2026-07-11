part of 'app_state.dart';

/// Classes, students, scoring and custom score buttons - mirrors the web
/// app's "Sınıflar" (`students`) and "Davranış" (`beh`) sections.
extension AppStateStudents on AppState {
  List<Student> getByClass(String? className) {
    if (className == null || className.isEmpty) return data.students;
    return data.students.where((s) => s.className == className).toList();
  }

  // ── Class codes ──────────────────────────────────────────────────────────

  String getClassCode(String cls) {
    final existing = data.classCodes[cls];
    if (existing != null && existing.isNotEmpty) return existing;
    final code = genClassCode();
    data.classCodes[cls] = code;
    save();
    return code;
  }

  void regenClassCode(String cls) {
    data.classCodes[cls] = genClassCode();
    save();
  }

  // ── Classes ──────────────────────────────────────────────────────────────

  bool addClass(String name) {
    final c = name.trim();
    if (c.isEmpty) return false;
    if (data.classes.contains(c)) return false;
    data.classes.add(c);
    data.classes.sort();
    getClassCode(c);
    save();
    return true;
  }

  void delClass(String c) {
    data.classes.remove(c);
    data.students.removeWhere((s) => s.className == c);
    data.classCodes.remove(c);
    save();
  }

  void clearClass(String c) {
    data.students.removeWhere((s) => s.className == c);
    save();
  }

  // ── Students ─────────────────────────────────────────────────────────────

  bool addStudent(String className, String name, String no) {
    final n = name.trim();
    if (n.isEmpty) return false;
    data.students.add(Student(
      id: uid(),
      className: className,
      name: n,
      no: no.trim(),
      score: 0,
      color: 0,
    ));
    save();
    return true;
  }

  void delStudent(String id) {
    data.students.removeWhere((s) => s.id == id);
    save();
  }

  bool editStudent(String id, String name, String no, int color) {
    final n = name.trim();
    if (n.isEmpty) return false;
    final s = data.students.firstWhereOrNull((x) => x.id == id);
    if (s == null) return false;
    s.name = n;
    s.no = no.trim();
    s.color = color;
    save();
    return true;
  }

  bool transferStudent(String id, String target) {
    final s = data.students.firstWhereOrNull((x) => x.id == id);
    if (s == null || target.isEmpty) return false;
    s.className = target;
    save();
    return true;
  }

  // ── Scoring ──────────────────────────────────────────────────────────────

  Future<void> changeScore(String id, int delta, {String? label, String note = ''}) async {
    final s = data.students.firstWhereOrNull((x) => x.id == id);
    if (s == null) return;
    s.score = (s.score) + delta;
    final n = note.trim().isNotEmpty ? note.trim() : pointText(delta, label);
    s.history.insert(0, HistoryEntry(d: delta, n: n, t: trDateTime(DateTime.now())));
    await save();
    unawaited(_teacherSync.syncScore(s.no, delta, n));
  }

  void resetScores(String cls) {
    for (final s in data.students.where((s) => s.className == cls)) {
      s.score = 0;
      s.history.clear();
    }
    save();
  }

  // ── Custom score buttons ─────────────────────────────────────────────────

  void saveCustomButtons(List<CustomButton> buttons) {
    data.customBtns = buttons.where((b) => b.label.trim().isNotEmpty).toList();
    save();
  }
}

extension _FirstWhereOrNull<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
