import 'package:flutter/foundation.dart';

import '../core/supabase_config.dart';
import 'models.dart';

/// Classes a teacher owns.
class TeacherClassesController extends ChangeNotifier {
  TeacherClassesController(this.teacherId) {
    refetch();
  }

  final String teacherId;
  List<ClassRow> classes = [];
  bool loading = true;
  Object? error;

  Future<void> refetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await supabase
          .from('classes')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: true);
      classes = (data as List).map((e) => ClassRow.fromJson(e as Map<String, dynamic>)).toList();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// Classes a student has joined.
class StudentClassesController extends ChangeNotifier {
  StudentClassesController(this.studentId) {
    refetch();
  }

  final String studentId;
  List<ClassRow> classes = [];
  bool loading = true;
  Object? error;

  Future<void> refetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await supabase.from('class_students').select('classes(*)').eq('student_id', studentId);
      classes = (data as List)
          .map((row) => row['classes'])
          .where((c) => c != null)
          .map((c) => ClassRow.fromJson(c as Map<String, dynamic>))
          .toList();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// Single class by id (used for headers/detail screens).
class ClassController extends ChangeNotifier {
  ClassController(this.classId) {
    refetch();
  }

  final String classId;
  ClassRow? classRow;
  bool loading = true;
  Object? error;

  Future<void> refetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await supabase.from('classes').select().eq('id', classId).single();
      classRow = ClassRow.fromJson(data);
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// Roster (students + their profiles) for a class.
class ClassRosterController extends ChangeNotifier {
  ClassRosterController(this.classId) {
    refetch();
  }

  final String classId;
  List<ClassRosterEntry> roster = [];
  bool loading = true;
  Object? error;

  Future<void> refetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await supabase
          .from('class_students')
          .select('student_id, joined_at, profiles(*)')
          .eq('class_id', classId)
          .order('joined_at', ascending: true);
      roster = (data as List).map((e) => ClassRosterEntry.fromJson(e as Map<String, dynamic>)).toList();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// Creates a new class for the current teacher. The DB trigger auto-provisions its Tahta board.
Future<({ClassRow? data, Object? error})> createClass(String teacherId, String name) async {
  try {
    final data = await supabase.from('classes').insert({'teacher_id': teacherId, 'name': name}).select().single();
    return (data: ClassRow.fromJson(data), error: null);
  } catch (e) {
    return (data: null, error: e);
  }
}

/// Joins the current student to a class using the teacher-shared join code.
Future<({Map<String, dynamic>? data, Object? error})> joinClassByCode(String code) async {
  try {
    final data = await supabase.rpc('join_class_by_code', params: {'p_code': code.trim()});
    final list = data as List?;
    if (list == null || list.isEmpty) return (data: null, error: null);
    return (data: list.first as Map<String, dynamic>, error: null);
  } catch (e) {
    return (data: null, error: e);
  }
}
