class Assignment {
  String id;
  String teacherId;
  String className;
  String type; // 'odev' | 'duyuru' | 'gorev'
  String title;
  String body;
  String? dueDate; // yyyy-MM-dd
  String? fileUrl;
  String? fileName;
  String? filePath;
  DateTime createdAt;

  Assignment({
    required this.id,
    required this.teacherId,
    required this.className,
    required this.type,
    required this.title,
    this.body = '',
    this.dueDate,
    this.fileUrl,
    this.fileName,
    this.filePath,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id']?.toString() ?? '',
        teacherId: json['teacher_id']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'odev',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        dueDate: json['due_date']?.toString(),
        fileUrl: json['file_url']?.toString(),
        fileName: json['file_name']?.toString(),
        filePath: json['file_path']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toInsertJson() => {
        'teacher_id': teacherId,
        'class_name': className,
        'type': type,
        'title': title,
        'body': body,
        'due_date': dueDate,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_path': filePath,
      };
}

const Map<String, String> asgTypeLabel = {
  'odev': '📘 Ödev',
  'duyuru': '📢 Duyuru',
  'gorev': '✅ Görev',
};
