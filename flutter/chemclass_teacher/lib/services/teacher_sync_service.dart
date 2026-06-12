import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Mirrors a score change into the separate "Öğretmenim" backend
/// (hardcoded project, independent from the configurable cloud sync),
/// so that the standalone Öğretmenim app stays in sync.
class TeacherSyncService {
  late final SupabaseClient _client;

  TeacherSyncService() {
    _client = SupabaseClient(teacherSyncUrl, teacherSyncAnonKey);
  }

  Future<void> syncScore(String studentNo, int delta, String note) async {
    if (studentNo.isEmpty) return;
    try {
      final student = await _client
          .from('teacher_students')
          .select('id')
          .eq('student_number', studentNo)
          .maybeSingle();
      if (student == null) return;
      final sid = student['id'];

      final existing = await _client
          .from('student_scores')
          .select('id,score')
          .eq('student_id', sid)
          .maybeSingle();

      if (existing != null) {
        final current = (existing['score'] as num?)?.toInt() ?? 0;
        await _client
            .from('student_scores')
            .update({'score': current + delta, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      } else {
        await _client.from('student_scores').insert({'student_id': sid, 'score': delta});
      }

      await _client.from('score_history').insert({
        'student_id': sid,
        'delta': delta,
        'note': note,
      });
    } catch (_) {
      // Best-effort sync; ignore failures (offline, missing student, etc).
    }
  }
}
