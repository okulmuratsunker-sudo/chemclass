import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_session.dart';
import '../services/notification_service.dart';

class SessionNotifier extends StateNotifier<StudentSession?> {
  SessionNotifier() : super(null) {
    _load();
  }

  static const _key = 'student_session';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final session =
          StudentSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      state = session;
      NotificationService.registerToken(session);
    }
  }

  Future<void> login(StudentSession session) async {
    state = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
    NotificationService.registerToken(session);
  }

  Future<void> logout() async {
    await NotificationService.unregisterToken();
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, StudentSession?>(
  (ref) => SessionNotifier(),
);
