class StudentSession {
  final String studentId;
  final String name;
  final String className;
  final String schoolNo;
  final String teacherId;

  const StudentSession({
    required this.studentId,
    required this.name,
    required this.className,
    required this.schoolNo,
    required this.teacherId,
  });

  factory StudentSession.fromJson(Map<String, dynamic> json) => StudentSession(
        studentId: json['studentId'] as String,
        name: json['name'] as String,
        className: json['className'] as String,
        schoolNo: json['schoolNo'] as String,
        teacherId: json['teacherId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'className': className,
        'schoolNo': schoolNo,
        'teacherId': teacherId,
      };
}
