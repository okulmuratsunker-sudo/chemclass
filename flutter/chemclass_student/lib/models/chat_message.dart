class ChatMessage {
  String id;
  String? studentId;
  String? className;
  String sender; // 'teacher' | 'student'
  String senderName;
  String body;
  DateTime createdAt;

  ChatMessage({
    required this.id,
    this.studentId,
    this.className,
    required this.sender,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        studentId: json['student_id']?.toString(),
        className: json['class_name']?.toString(),
        sender: json['sender']?.toString() ?? 'teacher',
        senderName: json['sender_name']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
