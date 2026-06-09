import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_data.dart';
import '../models/message.dart';
import '../models/teacher_models.dart';

class SupabaseService {
  static SupabaseClient get _sb => Supabase.instance.client;
  static String? get _userId => _sb.auth.currentUser?.id;

  // ─── Auth ───────────────────────────────────────────────────────────────
  static Future<void> signIn(String email, String password) async {
    await _sb.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUp(String email, String password) async {
    await _sb.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  // ─── App Data ────────────────────────────────────────────────────────────
  static Future<AppData> loadAppData() async {
    final uid = _userId;
    if (uid == null) return AppData();
    final row = await _sb
        .from('chemclass_data')
        .select('app_data')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return AppData();
    return AppData.fromJson(row['app_data'] as Map<String, dynamic>? ?? {});
  }

  static Future<void> saveAppData(AppData data) async {
    final uid = _userId;
    if (uid == null) return;
    await _sb.from('chemclass_data').upsert({
      'user_id': uid,
      'app_data': data.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Assignments ─────────────────────────────────────────────────────────
  static Future<List<Assignment>> loadAssignments() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('chemclass_assignments')
        .select()
        .eq('teacher_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Assignment.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<void> saveAssignment({
    required String className,
    required String type,
    required String title,
    String? body,
    DateTime? dueDate,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    await _sb.from('chemclass_assignments').insert({
      'teacher_id': uid,
      'class_name': className,
      'type': type,
      'title': title,
      'body': body,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
    });
  }

  static Future<void> deleteAssignment(String id) async {
    await _sb.from('chemclass_assignments').delete().eq('id', id);
  }

  // ─── Messages ─────────────────────────────────────────────────────────────
  static Future<List<TeacherMessage>> loadMessages() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('chemclass_messages')
        .select()
        .eq('teacher_id', uid)
        .order('created_at');
    return (rows as List)
        .map((r) => TeacherMessage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> sendMessage({
    required String? studentId,
    required String className,
    required String body,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    await _sb.from('chemclass_messages').insert({
      'teacher_id': uid,
      'student_id': studentId,
      'class_name': className,
      'sender': 'teacher',
      'sender_name': 'Öğretmen',
      'body': body.trim(),
    });
  }

  static RealtimeChannel subscribeMessages(void Function() onNew) {
    return _sb
        .channel('chemclass-teacher-$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chemclass_messages',
          callback: (_) => onNew(),
        )
        .subscribe();
  }

  // ─── Board Sessions ───────────────────────────────────────────────────────
  static Future<String> createBoardSession({
    required String className,
    required Map<String, dynamic> snapshot,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Oturum açılmamış');
    final code = _randomBoardCode();
    final expires = DateTime.now().add(const Duration(hours: 8));
    await _sb.from('chemclass_board_sessions').upsert({
      'code': code,
      'user_id': uid,
      'class_name': className,
      'app_data': snapshot,
      'active': true,
      'expires_at': expires.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return code;
  }

  static Future<void> updateBoardSession(
      String code, Map<String, dynamic> snapshot) async {
    await _sb
        .from('chemclass_board_sessions')
        .update({'app_data': snapshot, 'updated_at': DateTime.now().toIso8601String()})
        .eq('code', code);
  }

  static Future<void> closeBoardSession(String code) async {
    await _sb
        .from('chemclass_board_sessions')
        .update({'active': false})
        .eq('code', code);
  }

  static String _randomBoardCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // ─── Teacher Portfolio (Öğretmenim) ──────────────────────────────────────
  static Future<List<TeacherStudent>> loadTeacherStudents() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('teacher_students')
        .select()
        .eq('user_id', uid)
        .order('class_name')
        .order('name');
    return (rows as List)
        .map((r) => TeacherStudent.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveTeacherStudent(
      {String? id,
      required String name,
      required String studentNumber,
      required String className,
      String? notes}) async {
    final uid = _userId;
    if (uid == null) return;
    if (id != null) {
      await _sb.from('teacher_students').update({
        'name': name,
        'student_number': studentNumber,
        'class_name': className,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } else {
      await _sb.from('teacher_students').insert({
        'user_id': uid,
        'name': name,
        'student_number': studentNumber,
        'class_name': className,
        'notes': notes,
      });
    }
  }

  static Future<void> deleteTeacherStudent(String id) async {
    await _sb.from('teacher_students').delete().eq('id', id);
  }

  static Future<List<Grade>> loadGrades(String? studentId) async {
    final uid = _userId;
    if (uid == null) return [];
    var q = _sb.from('teacher_grades').select();
    if (studentId != null) q = q.eq('student_id', studentId);
    final rows = await q;
    return (rows as List).map((r) => Grade.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<void> saveGrade({
    required String studentId,
    required int semester,
    required String column,
    required double? value,
  }) async {
    await _sb.from('teacher_grades').upsert(
      {
        'student_id': studentId,
        'semester': semester,
        column: value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'student_id,semester',
    );
  }

  static Future<List<ScheduleSlot>> loadSchedule() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('teacher_schedule')
        .select()
        .eq('user_id', uid);
    return (rows as List)
        .map((r) => ScheduleSlot.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upsertScheduleSlot(
      {String? id, required int day, required int period, required String content}) async {
    final uid = _userId;
    if (uid == null) return;
    if (id != null) {
      await _sb.from('teacher_schedule').update({'content': content}).eq('id', id);
    } else {
      await _sb.from('teacher_schedule').insert({
        'user_id': uid,
        'day_index': day,
        'period_index': period,
        'content': content,
      });
    }
  }

  static Future<void> deleteScheduleSlot(String id) async {
    await _sb.from('teacher_schedule').delete().eq('id', id);
  }

  static Future<List<LessonPlan>> loadLessonPlans() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('teacher_plans')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => LessonPlan.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveLessonPlan({
    String? id,
    required String planType,
    required String title,
    DateTime? date,
    String? content,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    if (id != null) {
      await _sb.from('teacher_plans').update({
        'plan_type': planType,
        'title': title,
        'date': date?.toIso8601String().substring(0, 10),
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } else {
      await _sb.from('teacher_plans').insert({
        'user_id': uid,
        'plan_type': planType,
        'title': title,
        'date': date?.toIso8601String().substring(0, 10),
        'content': content,
      });
    }
  }

  static Future<void> deleteLessonPlan(String id) async {
    await _sb.from('teacher_plans').delete().eq('id', id);
  }

  static Future<List<ExamQuestion>> loadExamQuestions(
      {required int semester, required String examType}) async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _sb
        .from('exam_questions')
        .select()
        .eq('user_id', uid)
        .eq('semester', semester)
        .eq('exam_type', examType)
        .order('q_number');
    return (rows as List)
        .map((r) => ExamQuestion.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, double>> loadQuestionScores(
      List<String> questionIds) async {
    if (questionIds.isEmpty) return {};
    final rows = await _sb
        .from('question_scores')
        .select()
        .inFilter('question_id', questionIds);
    final result = <String, double>{};
    for (final r in rows as List) {
      result['${r['question_id']}_${r['student_id']}'] =
          (r['score'] as num).toDouble();
    }
    return result;
  }

  static Future<void> saveQuestionScore(
      {required String questionId,
      required String studentId,
      required double score}) async {
    await _sb.from('question_scores').upsert(
      {
        'question_id': questionId,
        'student_id': studentId,
        'score': score,
      },
      onConflict: 'question_id,student_id',
    );
  }
}
