import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_session.dart';
import '../models/student.dart';
import '../utils/constants.dart';

/// Thin wrapper around [SharedPreferences]: theme, the offline cache
/// (`students`+`sessions` snapshot) and the offline write queue, mirroring
/// the web app's `dt_theme`, `dt_v1_cache` and `dt_v1_queue` localStorage keys.
class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getTheme() async {
    final prefs = await _instance();
    return prefs.getString(prefsThemeKey);
  }

  Future<void> setTheme(String theme) async {
    final prefs = await _instance();
    await prefs.setString(prefsThemeKey, theme);
  }

  // ── Cache ──────────────────────────────────────────────────────────────

  Future<void> saveCache(List<Student> students, List<LessonSession> sessions) async {
    final prefs = await _instance();
    await prefs.setString(prefsCacheKey, jsonEncode({
      'students': students.map((s) => {'id': s.id, ...s.toJson()}).toList(),
      'sessions': sessions.map((s) => {'id': s.id, ...s.toJson()}).toList(),
    }));
  }

  Future<(List<Student>, List<LessonSession>)> loadCache() async {
    final prefs = await _instance();
    final raw = prefs.getString(prefsCacheKey);
    if (raw == null || raw.isEmpty) return (<Student>[], <LessonSession>[]);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final students = (json['students'] as List? ?? [])
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
      final sessions = (json['sessions'] as List? ?? [])
          .map((e) => LessonSession.fromJson(e as Map<String, dynamic>))
          .toList();
      return (students, sessions);
    } catch (_) {
      return (<Student>[], <LessonSession>[]);
    }
  }

  // ── Offline write queue ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await _instance();
    final raw = prefs.getString(prefsQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> addQueueOp(Map<String, dynamic> op) async {
    final q = await getQueue();
    q.add(op);
    final prefs = await _instance();
    await prefs.setString(prefsQueueKey, jsonEncode(q));
  }

  Future<void> clearQueue() async {
    final prefs = await _instance();
    await prefs.remove(prefsQueueKey);
  }
}
