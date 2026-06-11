/// Implemented by tables that have a single `id` primary key, so realtime
/// list updates can match rows by id.
abstract class Identifiable {
  String get id;
}

class Profile {
  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: (json['full_name'] as String?) ?? '',
        role: json['role'] as String,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ClassRow implements Identifiable {
  ClassRow({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    required this.createdAt,
  });

  @override
  final String id;
  final String teacherId;
  final String name;
  final String joinCode;
  final DateTime createdAt;

  factory ClassRow.fromJson(Map<String, dynamic> json) => ClassRow(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        name: json['name'] as String,
        joinCode: json['join_code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ClassRosterEntry {
  ClassRosterEntry({required this.studentId, required this.joinedAt, this.profile});

  final String studentId;
  final DateTime joinedAt;
  final Profile? profile;

  factory ClassRosterEntry.fromJson(Map<String, dynamic> json) => ClassRosterEntry(
        studentId: json['student_id'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        profile: json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
      );
}

class BehaviorPoint implements Identifiable {
  BehaviorPoint({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.givenBy,
    required this.points,
    this.reason,
    required this.createdAt,
  });

  @override
  final String id;
  final String classId;
  final String studentId;
  final String givenBy;
  final int points;
  final String? reason;
  final DateTime createdAt;

  factory BehaviorPoint.fromJson(Map<String, dynamic> json) => BehaviorPoint(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        studentId: json['student_id'] as String,
        givenBy: json['given_by'] as String,
        points: json['points'] as int,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Grade implements Identifiable {
  Grade({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.givenBy,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.createdAt,
  });

  @override
  final String id;
  final String classId;
  final String studentId;
  final String givenBy;
  final String title;
  final num score;
  final num maxScore;
  final DateTime createdAt;

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        studentId: json['student_id'] as String,
        givenBy: json['given_by'] as String,
        title: json['title'] as String,
        score: json['score'] as num,
        maxScore: json['max_score'] as num,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Message implements Identifiable {
  Message({
    required this.id,
    required this.classId,
    required this.senderId,
    this.recipientId,
    required this.content,
    this.readAt,
    required this.createdAt,
  });

  @override
  final String id;
  final String classId;
  final String senderId;
  final String? recipientId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        senderId: json['sender_id'] as String,
        recipientId: json['recipient_id'] as String?,
        content: json['content'] as String,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Homework implements Identifiable {
  Homework({
    required this.id,
    required this.classId,
    required this.createdBy,
    required this.title,
    this.description,
    this.dueDate,
    required this.createdAt,
  });

  @override
  final String id;
  final String classId;
  final String createdBy;
  final String title;
  final String? description;
  final String? dueDate;
  final DateTime createdAt;

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: json['due_date'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Announcement implements Identifiable {
  Announcement({
    required this.id,
    required this.classId,
    required this.createdBy,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  @override
  final String id;
  final String classId;
  final String createdBy;
  final String title;
  final String content;
  final DateTime createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ScheduleEntry implements Identifiable {
  ScheduleEntry({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.subjectName,
    required this.createdAt,
  });

  @override
  final String id;
  final String userId;
  final int dayOfWeek;
  final int periodNumber;
  final String subjectName;
  final DateTime createdAt;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        periodNumber: json['period_number'] as int,
        subjectName: json['subject_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class BoardSession {
  BoardSession({required this.id, required this.classId, required this.code, required this.createdAt});

  final String id;
  final String classId;
  final String code;
  final DateTime createdAt;

  factory BoardSession.fromJson(Map<String, dynamic> json) => BoardSession(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class BoardState {
  BoardState({required this.boardSessionId, required this.stateType, required this.payload, required this.updatedAt});

  final String boardSessionId;
  final String stateType;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;

  factory BoardState.fromJson(Map<String, dynamic> json) => BoardState(
        boardSessionId: json['board_session_id'] as String,
        stateType: json['state_type'] as String,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
