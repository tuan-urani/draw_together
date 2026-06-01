class GameSubmission {
  const GameSubmission({
    required this.id,
    required this.roundId,
    required this.submittedBy,
    required this.isTeamSubmission,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.createdAt,
    this.userId,
  });

  final String id;
  final String roundId;
  final String submittedBy;
  final bool isTeamSubmission;
  final String imagePath;
  final int width;
  final int height;
  final DateTime createdAt;
  final String? userId;

  factory GameSubmission.fromJson(Map<String, dynamic> json) {
    return GameSubmission(
      id: json['id'] as String,
      roundId: json['round_id'] as String,
      userId: json['user_id'] as String?,
      submittedBy: json['submitted_by'] as String,
      isTeamSubmission: json['is_team_submission'] as bool? ?? false,
      imagePath: json['image_path'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
