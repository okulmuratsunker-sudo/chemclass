import 'dart:convert';
import 'dart:math';

String uid() {
  final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final rand = Random().nextInt(0xFFFFFF).toRadixString(36).padLeft(6, '0');
  return '$now$rand';
}

String genClassCode() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final rand = Random();
  return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
}

class ScoreHistoryEntry {
  final int delta;
  final String note;
  final int timestamp;

  ScoreHistoryEntry({
    required this.delta,
    required this.note,
    required this.timestamp,
  });

  factory ScoreHistoryEntry.fromJson(Map<String, dynamic> j) =>
      ScoreHistoryEntry(
        delta: (j['d'] as num?)?.toInt() ?? 0,
        note: j['n'] as String? ?? '',
        timestamp: (j['t'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {'d': delta, 'n': note, 't': timestamp};

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
}

class Student {
  String id;
  String className;
  String name;
  String no;
  int color;
  List<ScoreHistoryEntry> history;

  Student({
    required this.id,
    required this.className,
    required this.name,
    required this.no,
    this.color = 0,
    List<ScoreHistoryEntry>? history,
  }) : history = history ?? [];

  factory Student.create(String className, String name, String no,
          {int color = 0}) =>
      Student(id: uid(), className: className, name: name, no: no, color: color);

  int get score => history.fold(0, (s, e) => s + e.delta);

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id']?.toString() ?? uid(),
        className: j['className'] as String? ?? '',
        name: j['name'] as String? ?? '',
        no: j['no']?.toString() ?? '',
        color: (j['color'] as num?)?.toInt() ?? 0,
        history: (j['history'] as List? ?? [])
            .map((e) =>
                ScoreHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'name': name,
        'no': no,
        'color': color,
        'history': history.map((e) => e.toJson()).toList(),
      };

  Student copyWith({
    String? className,
    String? name,
    String? no,
    int? color,
  }) =>
      Student(
        id: id,
        className: className ?? this.className,
        name: name ?? this.name,
        no: no ?? this.no,
        color: color ?? this.color,
        history: List.from(history),
      );
}

class CustomButton {
  int val;
  String label;

  CustomButton({required this.val, required this.label});

  factory CustomButton.fromJson(Map<String, dynamic> j) => CustomButton(
        val: (j['val'] as num?)?.toInt() ?? 0,
        label: j['label'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'val': val, 'label': label};
}

class AppData {
  List<String> classes;
  List<Student> students;
  // {'className_YYYY-MM-DD': {'studentId': 'P|A|E'}}
  Map<String, Map<String, String>> attendance;
  List<CustomButton> customBtns;
  Map<String, String> classCodes;

  AppData({
    List<String>? classes,
    List<Student>? students,
    Map<String, Map<String, String>>? attendance,
    List<CustomButton>? customBtns,
    Map<String, String>? classCodes,
  })  : classes = classes ?? [],
        students = students ?? [],
        attendance = attendance ?? {},
        customBtns = customBtns ?? [],
        classCodes = classCodes ?? {};

  List<Student> studentsOf(String cls) =>
      students.where((s) => s.className == cls).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Student? findStudent(String id) {
    try {
      return students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> attendanceFor(String cls, DateTime date) {
    final key =
        '${cls}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Map<String, String>.from(attendance[key] ?? {});
  }

  factory AppData.fromJson(Map<String, dynamic> j) {
    final rawAtt = j['attendance'];
    Map<String, Map<String, String>> att = {};
    if (rawAtt is Map) {
      for (final k in rawAtt.keys) {
        final v = rawAtt[k];
        if (v is Map) {
          att[k.toString()] =
              v.map((ki, vi) => MapEntry(ki.toString(), vi.toString()));
        }
      }
    }

    return AppData(
      classes: List<String>.from(j['classes'] as List? ?? []),
      students: (j['students'] as List? ?? [])
          .map((s) => Student.fromJson(s as Map<String, dynamic>))
          .toList(),
      attendance: att,
      customBtns: (j['customBtns'] as List? ?? [])
          .map((b) => CustomButton.fromJson(b as Map<String, dynamic>))
          .toList(),
      classCodes: Map<String, String>.from(j['classCodes'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'classes': classes,
        'students': students.map((s) => s.toJson()).toList(),
        'attendance': attendance,
        'customBtns': customBtns.map((b) => b.toJson()).toList(),
        'classCodes': classCodes,
        '_modified': DateTime.now().millisecondsSinceEpoch,
      };

  String toJsonString() => jsonEncode(toJson());

  AppData deepCopy() => AppData.fromJson(toJson());
}
