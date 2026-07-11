class ChatMessage {
  String id;
  String teacherId;
  String? studentId;
  String? className;
  String sender; // 'teacher' | 'student'
  String senderName;
  String body;
  DateTime createdAt;
  DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.teacherId,
    this.studentId,
    this.className,
    required this.sender,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        teacherId: json['teacher_id']?.toString() ?? '',
        studentId: json['student_id']?.toString(),
        className: json['class_name']?.toString(),
        sender: json['sender']?.toString() ?? 'teacher',
        senderName: json['sender_name']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        readAt: json['read_at'] != null
            ? DateTime.tryParse(json['read_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'teacher_id': teacherId,
        'student_id': studentId,
        'class_name': className,
        'sender': sender,
        'sender_name': senderName,
        'body': body,
      };
}
