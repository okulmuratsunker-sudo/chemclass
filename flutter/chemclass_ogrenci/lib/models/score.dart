class ScoreEntry {
  final String id;
  final int points;
  final String reason;
  final DateTime createdAt;

  const ScoreEntry({
    required this.id,
    required this.points,
    required this.reason,
    required this.createdAt,
  });

  bool get isPositive => points > 0;

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
        id: json['id'].toString(),
        points: (json['points'] as num).toInt(),
        reason: json['reason'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class ScoreSummary {
  final int totalScore;
  final int positive;
  final int negative;
  final int classAverage;
  final int rank;
  final int totalStudents;
  final List<LeaderboardEntry> leaderboard;
  final List<ScoreEntry> history;

  const ScoreSummary({
    required this.totalScore,
    required this.positive,
    required this.negative,
    required this.classAverage,
    required this.rank,
    required this.totalStudents,
    required this.leaderboard,
    required this.history,
  });
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int score;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.isMe,
  });
}
