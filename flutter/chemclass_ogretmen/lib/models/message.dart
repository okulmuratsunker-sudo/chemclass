class TeacherMessage {
  final String id;
  final String body;
  final String sender;
  final String? senderName;
  final String? studentId;
  final String? className;
  final DateTime createdAt;

  const TeacherMessage({
    required this.id,
    required this.body,
    required this.sender,
    this.senderName,
    this.studentId,
    this.className,
    required this.createdAt,
  });

  bool get isFromTeacher => sender == 'teacher';

  factory TeacherMessage.fromJson(Map<String, dynamic> j) => TeacherMessage(
        id: j['id'].toString(),
        body: j['body'] as String,
        sender: j['sender'] as String,
        senderName: j['sender_name'] as String?,
        studentId: j['student_id'] as String?,
        className: j['class_name'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class Assignment {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? className;
  final DateTime? dueDate;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;

  const Assignment({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.className,
    this.dueDate,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case 'odev':
        return '📘 Ödev';
      case 'duyuru':
        return '📢 Duyuru';
      case 'gorev':
        return '✅ Görev';
      default:
        return '📌 Diğer';
    }
  }

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        id: j['id'].toString(),
        type: j['type'] as String? ?? 'duyuru',
        title: j['title'] as String,
        body: j['body'] as String?,
        className: j['class_name'] as String?,
        dueDate: j['due_date'] != null
            ? DateTime.tryParse(j['due_date'] as String)
            : null,
        fileUrl: j['file_url'] as String?,
        fileName: j['file_name'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
