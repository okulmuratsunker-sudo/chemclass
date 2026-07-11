/// A single score change, mirroring the teacher app's `HistoryEntry`
/// (`{d: delta, n: label, t: ISO timestamp}`).
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

  DateTime? get time => DateTime.tryParse(t);
}
