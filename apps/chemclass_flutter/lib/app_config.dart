/// Static configuration that differs between the teacher (ChemClass) and
/// student (ChemClass Öğrenci) builds of this app.
class AppConfig {
  const AppConfig({required this.appName, required this.role, required this.roleLabel});

  final String appName;
  final String role; // "teacher" | "student"
  final String roleLabel; // "Öğretmen" | "Öğrenci"

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
}

const teacherAppConfig = AppConfig(appName: 'ChemClass', role: 'teacher', roleLabel: 'Öğretmen');
const studentAppConfig = AppConfig(appName: 'ChemClass Öğrenci', role: 'student', roleLabel: 'Öğrenci');
