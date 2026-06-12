part of 'app_state.dart';

/// Random group generator with persistent (per-session) group scores -
/// mirrors `makeGroups()` / `renderGroups()`. Groups themselves are not
/// persisted to disk, matching the web app.
extension AppStateGroups on AppState {
  /// Returns an error message, or `null` on success.
  String? makeGroups(String className) {
    final ss = getByClass(className);
    if (ss.isEmpty) return 'Öğrenci yok';

    final shuffled = List<Student>.from(ss)..shuffle(Random());
    final v = max(1, groupVal);
    final arr = <List<Student>>[];

    if (groupMode == 'count') {
      final count = min(v, shuffled.length);
      for (var i = 0; i < count; i++) {
        arr.add([]);
      }
      for (var i = 0; i < shuffled.length; i++) {
        arr[i % arr.length].add(shuffled[i]);
      }
    } else {
      for (var i = 0; i < shuffled.length; i += v) {
        arr.add(shuffled.sublist(i, min(i + v, shuffled.length)));
      }
    }

    groups = List.generate(
      arr.length,
      (i) => StudyGroup(id: uid(), name: 'Grup ${i + 1}', score: 0, members: arr[i]),
    );
    setBoardView('groups');
    notify();
    return null;
  }

  void renameGroup(int index, String name) {
    if (index < 0 || index >= groups.length) return;
    groups[index].name = name;
    notify();
    scheduleBoardUpdate();
  }

  void incrementGroupScore(int index) {
    if (index < 0 || index >= groups.length) return;
    groups[index].score++;
    notify();
    scheduleBoardUpdate();
  }

  void decrementGroupScore(int index) {
    if (index < 0 || index >= groups.length) return;
    groups[index].score--;
    notify();
    scheduleBoardUpdate();
  }
}
