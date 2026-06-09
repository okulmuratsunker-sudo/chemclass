class Message {
  final String id;
  final String body;
  final String sender;
  final String? senderName;
  final DateTime createdAt;
  final String? readAt;

  const Message({
    required this.id,
    required this.body,
    required this.sender,
    this.senderName,
    required this.createdAt,
    this.readAt,
  });

  bool get isFromStudent => sender == 'student';
  bool get isRead => readAt != null;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'].toString(),
        body: json['body'] as String,
        sender: json['sender'] as String,
        senderName: json['sender_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        readAt: json['read_at'] as String?,
      );
}
