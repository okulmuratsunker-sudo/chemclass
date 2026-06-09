class Assignment {
  final String id;
  final String type;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Assignment({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
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

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'].toString(),
        type: json['type'] as String? ?? 'duyuru',
        title: json['title'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String).toLocal()
            : null,
      );
}
