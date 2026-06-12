import 'student.dart';

class CustomButton {
  int val;
  String label;

  CustomButton({required this.val, required this.label});

  factory CustomButton.fromJson(Map<String, dynamic> json) => CustomButton(
        val: (json['val'] as num?)?.toInt() ?? 0,
        label: json['label']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'val': val, 'label': label};
}

class AppData {
  List<String> classes;
  List<Student> students;
  // key: "{className}_{yyyy-MM-dd}" -> { studentId: 'P'|'A'|'E'|'' }
  Map<String, Map<String, String>> attendance;
  List<CustomButton> customBtns;
  Map<String, String> classCodes;
  int modified;

  AppData({
    List<String>? classes,
    List<Student>? students,
    Map<String, Map<String, String>>? attendance,
    List<CustomButton>? customBtns,
    Map<String, String>? classCodes,
    this.modified = 0,
  })  : classes = classes ?? [],
        students = students ?? [],
        attendance = attendance ?? {},
        customBtns = customBtns ?? [],
        classCodes = classCodes ?? {};

  factory AppData.empty() => AppData();

  factory AppData.fromJson(Map<String, dynamic> json) {
    final attendanceRaw = json['attendance'] as Map<String, dynamic>? ?? {};
    final attendance = <String, Map<String, String>>{};
    attendanceRaw.forEach((key, value) {
      final inner = <String, String>{};
      (value as Map<String, dynamic>? ?? {}).forEach((k, v) {
        inner[k] = v?.toString() ?? '';
      });
      attendance[key] = inner;
    });

    final classCodesRaw = json['classCodes'] as Map<String, dynamic>? ?? {};
    final classCodes = <String, String>{};
    classCodesRaw.forEach((k, v) => classCodes[k] = v?.toString() ?? '');

    return AppData(
      classes: (json['classes'] as List? ?? []).map((e) => e.toString()).toList(),
      students: (json['students'] as List? ?? [])
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendance: attendance,
      customBtns: (json['customBtns'] as List? ?? [])
          .map((e) => CustomButton.fromJson(e as Map<String, dynamic>))
          .toList(),
      classCodes: classCodes,
      modified: (json['_modified'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'classes': classes,
        'students': students.map((e) => e.toJson()).toList(),
        'attendance': attendance,
        'customBtns': customBtns.map((e) => e.toJson()).toList(),
        'classCodes': classCodes,
        '_modified': modified,
      };
}
