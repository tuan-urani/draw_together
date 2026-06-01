class GameScore {
  const GameScore({
    required this.id,
    required this.roundId,
    required this.submissionId,
    required this.similarityScore,
    required this.winner,
    required this.createdAt,
    this.userId,
    this.teamScore,
  });

  final String id;
  final String roundId;
  final String submissionId;
  final String? userId;
  final int? teamScore;
  final int similarityScore;
  final bool winner;
  final DateTime createdAt;

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id'] as String,
      roundId: json['round_id'] as String? ?? json['roundId'] as String,
      submissionId:
          json['submission_id'] as String? ?? json['submissionId'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      teamScore: json['team_score'] as int? ?? json['teamScore'] as int?,
      similarityScore:
          json['similarity_score'] as int? ?? json['similarityScore'] as int,
      winner: json['winner'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
    );
  }
}
