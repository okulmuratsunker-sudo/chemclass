import 'history_entry.dart';

/// The logged-in student's full record, as returned by `student_get_data`.
class StudentInfo {
  final String id;
  final String name;
  final String no;
  final String className;
  final int score;
  final int color;
  final List<HistoryEntry> history;

  StudentInfo({
    required this.id,
    required this.name,
    required this.no,
    required this.className,
    required this.score,
    required this.color,
    required this.history,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        no: json['no']?.toString() ?? '',
        className: json['className']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        color: (json['color'] as num?)?.toInt() ?? 0,
        history: (json['history'] as List? ?? [])
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
