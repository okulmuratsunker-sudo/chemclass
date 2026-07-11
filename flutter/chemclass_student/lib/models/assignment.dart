class Assignment {
  String id;
  String className;
  String type; // 'odev' | 'duyuru' | 'gorev'
  String title;
  String body;
  String? dueDate; // yyyy-MM-dd
  String? fileUrl;
  String? fileName;
  DateTime createdAt;

  Assignment({
    required this.id,
    required this.className,
    required this.type,
    required this.title,
    this.body = '',
    this.dueDate,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'odev',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        dueDate: json['due_date']?.toString(),
        fileUrl: json['file_url']?.toString(),
        fileName: json['file_name']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

const Map<String, String> asgTypeLabel = {
  'odev': '📘 Ödev',
  'duyuru': '📢 Duyuru',
  'gorev': '✅ Görev',
};
