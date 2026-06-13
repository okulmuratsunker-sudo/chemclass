import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_session.dart';
import '../models/student.dart';
import '../utils/constants.dart';

/// Wraps the Supabase client for the Ders Takip backend: auth plus CRUD on
/// the `students` and `sessions` tables.
class SupabaseService {
  final SupabaseClient _client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  User? get currentUser => _client.auth.currentUser;

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<User?> getSession() async => _client.auth.currentSession?.user;

  // ── Students ───────────────────────────────────────────────────────────

  Future<List<Student>> fetchStudents() async {
    final rows = await _client.from('students').select('*').order('name');
    return List<Map<String, dynamic>>.from(rows).map(Student.fromJson).toList();
  }

  Future<Student> insertStudent(Map<String, dynamic> data) async {
    final row = await _client.from('students').insert(data).select().single();
    return Student.fromJson(row);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _client.from('students').update(data).eq('id', id);
  }

  Future<void> deleteStudent(String id) async {
    await _client.from('students').delete().eq('id', id);
  }

  // ── Sessions ───────────────────────────────────────────────────────────

  Future<List<LessonSession>> fetchSessions() async {
    final rows = await _client.from('sessions').select('*').order('date', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(LessonSession.fromJson).toList();
  }

  Future<List<LessonSession>> fetchSessionsByStudent(String studentId, {bool ascending = false}) async {
    final rows = await _client
        .from('sessions')
        .select('*')
        .eq('student_id', studentId)
        .order('date', ascending: ascending);
    return List<Map<String, dynamic>>.from(rows).map(LessonSession.fromJson).toList();
  }

  Future<LessonSession> insertSession(Map<String, dynamic> data) async {
    final row = await _client.from('sessions').insert(data).select().single();
    return LessonSession.fromJson(row);
  }

  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    await _client.from('sessions').update(data).eq('id', id);
  }

  Future<void> deleteSession(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  Future<void> deleteSessionsByStudent(String studentId) async {
    await _client.from('sessions').delete().eq('student_id', studentId);
  }
}
