part of 'app_state.dart';

/// Random student picker - mirrors `pickStudent()` / `resetPick()`.
extension AppStatePick on AppState {
  void resetPick() {
    picked.clear();
    lastPick = null;
    isSpinning = false;
    pickResultName = '?';
    pickResultInfo = '';
    notify();
  }

  /// Runs the ~720ms "slot machine" spin animation and lands on a student
  /// who hasn't been picked in the last 5 draws (if possible).
  /// Returns an info message (e.g. when the last-5 rule had to be relaxed),
  /// or `null` on success, or an error message if nothing could be picked.
  Future<String?> pickStudent(String className) async {
    if (className.isEmpty) return 'Önce sınıf seçin';
    final all = getByClass(className);
    if (all.isEmpty) return 'Bu sınıfta öğrenci yok';

    final recentIds = picked.length > 5 ? picked.sublist(picked.length - 5) : List<String>.from(picked);
    var rem = all.where((s) => !recentIds.contains(s.id)).toList();
    String? info;
    if (rem.isEmpty) {
      rem = all;
      info = 'Sınıf küçük — son 5 kuralı gevşetildi';
    }

    isSpinning = true;
    pickResultInfo = '';
    notify();

    final chosen = rem[Random().nextInt(rem.length)];
    final allNames = rem.map((s) => s.name).toList();

    for (var spins = 0; spins < 12; spins++) {
      spinName = allNames[spins % allNames.length];
      notify();
      await Future.delayed(const Duration(milliseconds: 60));
    }

    isSpinning = false;
    lastPick = chosen.id;
    picked.add(chosen.id);
    pickResultName = chosen.name;
    pickResultInfo = 'No: ${chosen.no.isNotEmpty ? chosen.no : '-'}';
    lastPickTime = DateTime.now();
    setBoardView('pick');
    notify();
    return info;
  }

  /// Last 8 picked names, most-recent first.
  List<String> get recentPickedNames {
    final names = <String>[];
    for (final id in picked.reversed.take(8)) {
      final s = data.students.firstWhereOrNull((x) => x.id == id);
      if (s != null) names.add(s.name);
    }
    return names;
  }

  Student? get lastPickedStudent {
    if (lastPick == null) return null;
    return data.students.firstWhereOrNull((s) => s.id == lastPick);
  }
}
