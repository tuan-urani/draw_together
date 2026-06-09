class GameScore {
  const GameScore({
    required this.id,
    required this.roundId,
    required this.submissionId,
    required this.similarityScore,
    required this.winner,
    required this.createdAt,
    this.rationale = const <String>[],
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
  final List<String> rationale;
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
      rationale: _rationaleFromJson(json['rationale']),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
    );
  }

  static List<String> _rationaleFromJson(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String) {
      final rationale = value.trim();
      return rationale.isEmpty ? const <String>[] : <String>[rationale];
    }

    return const <String>[];
  }
}
