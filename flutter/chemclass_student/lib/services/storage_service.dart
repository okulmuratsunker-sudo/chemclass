import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_entry.dart';
import '../models/student_session.dart';
import '../utils/constants.dart';

/// Local persistence: session token, theme, "Ders Programı" schedule and the
/// set of assignment/message ids already notified about.
class StorageService {
  Future<StudentSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsSessionKey);
    if (raw == null) return null;
    try {
      return StudentSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(StudentSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsSessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsSessionKey);
  }

  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsThemeKey);
  }

  Future<void> setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsThemeKey, value);
  }

  Future<List<ScheduleEntry>> loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsScheduleKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSchedule(List<ScheduleEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsScheduleKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<Set<String>> getSeenIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);
    return raw?.toSet() ?? {};
  }

  Future<void> setSeenIds(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }
}
