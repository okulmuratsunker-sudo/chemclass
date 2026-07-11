class HistoryEntry {
  final int d;
  final String n;
  final String t;

  HistoryEntry({required this.d, required this.n, required this.t});

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        d: (json['d'] as num?)?.toInt() ?? 0,
        n: json['n']?.toString() ?? '',
        t: json['t']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'d': d, 'n': n, 't': t};
}

class Student {
  String id;
  String className;
  String name;
  String no;
  int score;
  List<HistoryEntry> history;
  int color;

  Student({
    required this.id,
    required this.className,
    required this.name,
    this.no = '',
    this.score = 0,
    List<HistoryEntry>? history,
    this.color = 0,
  }) : history = history ?? [];

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id']?.toString() ?? '',
        className: json['className']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        no: json['no']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        history: (json['history'] as List? ?? [])
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        color: (json['color'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'name': name,
        'no': no,
        'score': score,
        'history': history.map((e) => e.toJson()).toList(),
        'color': color,
      };

  /// Compact snapshot used for board sessions.
  Map<String, dynamic> toBoardJson() => {
        'id': id,
        'name': name,
        'no': no,
        'className': className,
        'score': score,
        'color': color,
      };
}
