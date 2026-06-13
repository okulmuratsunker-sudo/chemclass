/// Mirrors a row of the `sessions` table (a single lesson).
class LessonSession {
  final String id;
  final String studentId;
  final String date; // "YYYY-MM-DD"
  final double duration; // hours
  final double amount;
  final bool paid;
  final String? notes;

  const LessonSession({
    required this.id,
    required this.studentId,
    required this.date,
    required this.duration,
    required this.amount,
    required this.paid,
    this.notes,
  });

  factory LessonSession.fromJson(Map<String, dynamic> json) => LessonSession(
        id: json['id'].toString(),
        studentId: json['student_id'].toString(),
        date: (json['date'] as String?) ?? '',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paid: json['paid'] as bool? ?? false,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'date': date,
        'duration': duration,
        'amount': amount,
        'paid': paid,
        'notes': notes,
      };

  LessonSession copyWith({
    String? id,
    String? studentId,
    String? date,
    double? duration,
    double? amount,
    bool? paid,
    String? notes,
  }) => LessonSession(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        date: date ?? this.date,
        duration: duration ?? this.duration,
        amount: amount ?? this.amount,
        paid: paid ?? this.paid,
        notes: notes ?? this.notes,
      );
}
