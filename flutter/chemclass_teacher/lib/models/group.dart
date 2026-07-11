import 'student.dart';

class StudyGroup {
  String id;
  String name;
  int score;
  List<Student> members;

  StudyGroup({
    required this.id,
    required this.name,
    this.score = 0,
    List<Student>? members,
  }) : members = members ?? [];

  Map<String, dynamic> toBoardJson() => {
        'name': name,
        'score': score,
        'members': members.map((s) => s.name).toList(),
      };
}
