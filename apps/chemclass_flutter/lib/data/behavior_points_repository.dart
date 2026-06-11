import '../core/supabase_config.dart';

Future<Object?> giveBehaviorPoint({
  required String classId,
  required String studentId,
  required String givenBy,
  required int points,
  String? reason,
}) async {
  try {
    await supabase.from('behavior_points').insert({
      'class_id': classId,
      'student_id': studentId,
      'given_by': givenBy,
      'points': points,
      'reason': reason,
    });
    return null;
  } catch (e) {
    return e;
  }
}
