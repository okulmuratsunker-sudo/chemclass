class LeaderboardEntry {
  final String id;
  final String name;
  final int score;
  final int color;

  LeaderboardEntry({required this.id, required this.name, required this.score, required this.color});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        color: (json['color'] as num?)?.toInt() ?? 0,
      );
}
