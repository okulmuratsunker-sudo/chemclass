import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_session.dart';
import '../models/message.dart';
import '../models/assignment.dart';
import '../models/score.dart';

class SupabaseService {
  static final _sb = Supabase.instance.client;

  // Sınıf kodu + okul numarasıyla öğrenci bul
  static Future<StudentSession?> login(String classCode, String schoolNo) async {
    final code = classCode.trim().toUpperCase();
    final no = schoolNo.trim();

    final rows = await _sb
        .from('chemclass_data')
        .select('user_id, app_data')
        .limit(200);

    for (final row in rows) {
      final appData = row['app_data'] as Map<String, dynamic>? ?? {};
      final students = (appData['students'] as List<dynamic>?) ?? [];
      final classCodes = (appData['classCodes'] as Map<String, dynamic>?) ?? {};

      for (final s in students) {
        final student = s as Map<String, dynamic>;
        final cls = student['className'] as String? ?? '';
        final storedCode = classCodes[cls] as String?;
        if (storedCode != null &&
            storedCode.toUpperCase() == code &&
            student['no'].toString() == no) {
          return StudentSession(
            studentId: student['id'].toString(),
            name: student['name'] as String,
            className: cls,
            schoolNo: no,
            teacherId: row['user_id'] as String,
          );
        }
      }
    }
    return null;
  }

  // Mesajları yükle (öğrenci ↔ öğretmen + sınıf duyuruları)
  static Future<List<Message>> loadMessages(StudentSession session) async {
    final tid = session.teacherId;
    final sid = session.studentId;
    final cls = session.className;

    final results = await Future.wait([
      _sb
          .from('chemclass_messages')
          .select()
          .eq('teacher_id', tid)
          .eq('student_id', sid)
          .order('created_at'),
      _sb
          .from('chemclass_messages')
          .select()
          .eq('teacher_id', tid)
          .isFilter('student_id', null)
          .eq('class_name', cls)
          .order('created_at'),
      _sb
          .from('chemclass_messages')
          .select()
          .eq('teacher_id', tid)
          .isFilter('student_id', null)
          .isFilter('class_name', null)
          .order('created_at'),
    ]);

    final allMessages = [
      ...results[0] as List,
      ...results[1] as List,
      ...results[2] as List,
    ];

    allMessages.sort((a, b) => (a['created_at'] as String)
        .compareTo(b['created_at'] as String));

    return allMessages
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // Mesaj gönder
  static Future<void> sendMessage(StudentSession session, String body) async {
    await _sb.from('chemclass_messages').insert({
      'teacher_id': session.teacherId,
      'student_id': session.studentId,
      'class_name': session.className,
      'sender': 'student',
      'sender_name': session.name,
      'body': body.trim(),
    });
  }

  // Mesajları okundu işaretle
  static Future<void> markMessagesRead(
      StudentSession session, List<String> ids) async {
    if (ids.isEmpty) return;
    await _sb
        .from('chemclass_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .inFilter('id', ids);
  }

  // Ödevler & duyurular
  static Future<List<Assignment>> loadAssignments(
      StudentSession session) async {
    final rows = await _sb
        .from('chemclass_assignments')
        .select()
        .eq('teacher_id', session.teacherId)
        .eq('class_name', session.className)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => Assignment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // Puan özeti hesapla
  static Future<ScoreSummary> loadScores(StudentSession session) async {
    // Öğretmenin tüm uygulama verisini çek
    final row = await _sb
        .from('chemclass_data')
        .select('app_data')
        .eq('user_id', session.teacherId)
        .maybeSingle();

    if (row == null) {
      return ScoreSummary(
          totalScore: 0,
          positive: 0,
          negative: 0,
          classAverage: 0,
          rank: 0,
          totalStudents: 0,
          leaderboard: [],
          history: []);
    }

    final appData = row['app_data'] as Map<String, dynamic>? ?? {};
    final students = (appData['students'] as List<dynamic>?) ?? [];
    final attendance = (appData['attendance'] as Map<String, dynamic>?) ?? {};

    // Puan geçmişi
    final myHistory = <ScoreEntry>[];
    int totalScore = 0;
    int positive = 0;
    int negative = 0;

    final myLog = attendance[session.studentId] as List<dynamic>? ?? [];
    for (final entry in myLog) {
      final e = entry as Map<String, dynamic>;
      if (e['type'] == 'puan') {
        final pts = (e['points'] as num?)?.toInt() ?? 0;
        final reason = e['reason'] as String? ?? '';
        final createdAt = e['date'] != null
            ? DateTime.tryParse(e['date'] as String) ?? DateTime.now()
            : DateTime.now();
        myHistory.add(ScoreEntry(
          id: createdAt.millisecondsSinceEpoch.toString(),
          points: pts,
          reason: reason,
          createdAt: createdAt,
        ));
        totalScore += pts;
        if (pts > 0) positive += pts;
        if (pts < 0) negative += pts.abs();
      }
    }
    myHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Sınıf sıralaması
    final classStudents = students
        .where((s) =>
            (s as Map<String, dynamic>)['className'] == session.className)
        .toList();

    final scores = <Map<String, dynamic>>[];
    for (final s in classStudents) {
      final st = s as Map<String, dynamic>;
      final sId = st['id'].toString();
      final sLog = attendance[sId] as List<dynamic>? ?? [];
      int sScore = 0;
      for (final e in sLog) {
        if ((e as Map<String, dynamic>)['type'] == 'puan') {
          sScore += ((e['points'] as num?)?.toInt() ?? 0);
        }
      }
      scores.add({'id': sId, 'name': st['name'], 'score': sScore});
    }

    scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    int rank = 1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i]['id'] == session.studentId) {
        rank = i + 1;
        break;
      }
    }

    final classAvg = scores.isEmpty
        ? 0
        : scores.map((s) => s['score'] as int).reduce((a, b) => a + b) ~/
            scores.length;

    final leaderboard = scores
        .take(10)
        .toList()
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              rank: e.key + 1,
              name: e.value['name'] as String,
              score: e.value['score'] as int,
              isMe: e.value['id'] == session.studentId,
            ))
        .toList();

    return ScoreSummary(
      totalScore: totalScore,
      positive: positive,
      negative: negative,
      classAverage: classAvg,
      rank: rank,
      totalStudents: scores.length,
      leaderboard: leaderboard,
      history: myHistory,
    );
  }

  // Realtime mesaj aboneliği
  static RealtimeChannel subscribeMessages(
      StudentSession session, void Function() onNewMessage) {
    return Supabase.instance.client
        .channel('chemclass-student-${session.studentId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chemclass_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: session.teacherId,
          ),
          callback: (_) => onNewMessage(),
        )
        .subscribe();
  }
}
