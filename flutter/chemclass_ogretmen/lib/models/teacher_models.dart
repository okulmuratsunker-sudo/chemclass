// Öğretmenim/not defteri veri modelleri

class TeacherStudent {
  final String id;
  final String name;
  final String studentNumber;
  final String className;
  final String? notes;

  const TeacherStudent({
    required this.id,
    required this.name,
    required this.studentNumber,
    required this.className,
    this.notes,
  });

  factory TeacherStudent.fromJson(Map<String, dynamic> j) => TeacherStudent(
        id: j['id'] as String,
        name: j['name'] as String,
        studentNumber: j['student_number'] as String? ?? '',
        className: j['class_name'] as String? ?? '',
        notes: j['notes'] as String?,
      );
}

class Grade {
  final String studentId;
  final int semester;
  final double? w1, w2, oral, perf, perf2, project, proj2;

  const Grade({
    required this.studentId,
    required this.semester,
    this.w1,
    this.w2,
    this.oral,
    this.perf,
    this.perf2,
    this.project,
    this.proj2,
  });

  double? get donemAvg {
    final vals = [w1, w2, oral, perf, perf2, project, proj2]
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  int? get donemInt {
    final avg = donemAvg;
    return avg != null ? avg.round() : null;
  }

  factory Grade.fromJson(Map<String, dynamic> j) => Grade(
        studentId: j['student_id'] as String,
        semester: (j['semester'] as num).toInt(),
        w1: (j['w1'] as num?)?.toDouble(),
        w2: (j['w2'] as num?)?.toDouble(),
        oral: (j['oral'] as num?)?.toDouble(),
        perf: (j['perf'] as num?)?.toDouble(),
        perf2: (j['perf2'] as num?)?.toDouble(),
        project: (j['project'] as num?)?.toDouble(),
        proj2: (j['proj2'] as num?)?.toDouble(),
      );
}

class ScheduleSlot {
  final String id;
  final int dayIndex;
  final int periodIndex;
  final String content;

  const ScheduleSlot({
    required this.id,
    required this.dayIndex,
    required this.periodIndex,
    required this.content,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
        id: j['id'] as String,
        dayIndex: (j['day_index'] as num).toInt(),
        periodIndex: (j['period_index'] as num).toInt(),
        content: j['content'] as String? ?? '',
      );
}

class LessonPlan {
  final String id;
  final String planType;
  final String title;
  final DateTime? date;
  final String? content;
  final DateTime createdAt;

  const LessonPlan({
    required this.id,
    required this.planType,
    required this.title,
    this.date,
    this.content,
    required this.createdAt,
  });

  String get typeLabel {
    switch (planType) {
      case 'gun':
        return '📅 Günlük';
      case 'unite':
        return '📖 Ünite';
      case 'yillik':
        return '📆 Yıllık';
      default:
        return '📌 Plan';
    }
  }

  factory LessonPlan.fromJson(Map<String, dynamic> j) => LessonPlan(
        id: j['id'] as String,
        planType: j['plan_type'] as String? ?? 'gun',
        title: j['title'] as String,
        date: j['date'] != null ? DateTime.tryParse(j['date'] as String) : null,
        content: j['content'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class ExamQuestion {
  final String id;
  final int semester;
  final String examType;
  final int qNumber;
  final double maxPoints;
  final String? topic;

  const ExamQuestion({
    required this.id,
    required this.semester,
    required this.examType,
    required this.qNumber,
    required this.maxPoints,
    this.topic,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
        id: j['id'] as String,
        semester: (j['semester'] as num).toInt(),
        examType: j['exam_type'] as String,
        qNumber: (j['q_number'] as num).toInt(),
        maxPoints: (j['max_points'] as num).toDouble(),
        topic: j['topic'] as String?,
      );
}

class ItemAnalysisResult {
  final ExamQuestion question;
  final double difficulty; // p indeksi
  final double discrimination; // d indeksi
  final double classAvg;

  const ItemAnalysisResult({
    required this.question,
    required this.difficulty,
    required this.discrimination,
    required this.classAvg,
  });

  String get difficultyLabel {
    if (difficulty >= 0.70) return 'Kolay';
    if (difficulty >= 0.40) return 'Orta';
    if (difficulty >= 0.20) return 'Zor';
    return 'Çok Zor';
  }

  String get discriminationLabel {
    if (discrimination >= 0.40) return 'İyi';
    if (discrimination >= 0.30) return 'Yeterli';
    if (discrimination >= 0.20) return 'Zayıf';
    return 'Çok Zayıf';
  }
}
