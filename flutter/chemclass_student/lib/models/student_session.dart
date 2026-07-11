/// The logged-in student's session, returned by the `student_login` RPC and
/// persisted locally so the student stays logged in between app launches.
class StudentSession {
  String token;
  String studentId;
  String studentName;
  String className;
  int score;

  StudentSession({
    required this.token,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.score,
  });

  factory StudentSession.fromJson(Map<String, dynamic> json) => StudentSession(
        token: json['token']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? '',
        studentName: json['student_name']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'student_id': studentId,
        'student_name': studentName,
        'class_name': className,
        'score': score,
      };
}
