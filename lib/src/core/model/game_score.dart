class GameScore {
  const GameScore({
    required this.id,
    required this.roundId,
    required this.submissionId,
    required this.similarityScore,
    required this.winner,
    required this.createdAt,
    this.rationale = const <String>[],
    this.rationaleLocalized = const <String, List<String>>{},
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
  final Map<String, List<String>> rationaleLocalized;
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
      rationale: _rationaleFallbackFromJson(json['rationale']),
      rationaleLocalized: _rationaleLocalizedFromJson(
        json['rationale_localized'] ?? json['rationaleLocalized'],
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
    );
  }

  List<String> rationaleForLocale(String? languageCode) {
    final locale = _normalizeLanguageCode(languageCode);
    return rationaleLocalized[locale] ?? rationaleLocalized['en'] ?? rationale;
  }

  Map<String, List<String>> get rationaleLocalizedFallback {
    if (rationaleLocalized.isNotEmpty) return rationaleLocalized;
    return rationale.isEmpty
        ? const <String, List<String>>{}
        : <String, List<String>>{'en': rationale};
  }

  static List<String> _rationaleFallbackFromJson(Object? value) {
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

  static Map<String, List<String>> _rationaleLocalizedFromJson(Object? value) {
    if (value is Map) {
      final result = <String, List<String>>{};
      for (final entry in value.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        if (key.isEmpty) continue;

        final items = _rationaleFallbackFromJson(entry.value);
        if (items.isNotEmpty) {
          result[key] = items;
        }
      }
      if (result.isNotEmpty) return result;
    }

    final fallback = _rationaleFallbackFromJson(value);
    return fallback.isEmpty
        ? const <String, List<String>>{}
        : <String, List<String>>{'en': fallback};
  }

  static String _normalizeLanguageCode(String? languageCode) {
    final code = languageCode?.trim().toLowerCase() ?? '';
    if (code.startsWith('ja')) return 'ja';
    if (code.startsWith('vi')) return 'vi';
    return 'en';
  }
}
