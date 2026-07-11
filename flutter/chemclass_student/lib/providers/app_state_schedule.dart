part of 'app_state.dart';

/// Ders Programı — a local-only personal weekly schedule (no web-app
/// equivalent / no backend storage).
extension AppStateSchedule on AppState {
  List<ScheduleEntry> scheduleForDay(int day) {
    final list = schedule.where((e) => e.day == day).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// Today's lessons (Monday = weekday 1 .. Sunday = weekday 7).
  List<ScheduleEntry> get todaySchedule => scheduleForDay((DateTime.now().weekday - 1) % 7);

  Future<void> addScheduleEntry(ScheduleEntry entry) async {
    schedule.add(entry);
    await _storage.saveSchedule(schedule);
    notify();
  }

  Future<void> updateScheduleEntry(ScheduleEntry entry) async {
    final idx = schedule.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) schedule[idx] = entry;
    await _storage.saveSchedule(schedule);
    notify();
  }

  Future<void> deleteScheduleEntry(String id) async {
    schedule.removeWhere((e) => e.id == id);
    await _storage.saveSchedule(schedule);
    notify();
  }
}
