import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_score.dart';

class ScoringRepository {
  ScoringRepository(this._client);

  final SupabaseClient _client;

  Future<GameScore> scoreRound(String roundId) async {
    final scores = await scoreRoundScores(roundId);
    if (scores.isEmpty) {
      throw const FormatException('Invalid score payload.');
    }

    return scores.first;
  }

  Future<List<GameScore>> scoreRoundScores(String roundId) async {
    final response = await _client.functions.invoke(
      'score-round',
      body: <String, dynamic>{
        'roundId': roundId,
        'locale': Get.locale?.languageCode ?? 'en',
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid scoring response.');
    }

    final scores = data['scores'];
    if (scores is List<dynamic>) {
      return scores
          .map((score) => GameScore.fromJson(Map<String, dynamic>.from(score)))
          .toList(growable: false);
    }

    final score = data['score'];
    if (score is Map<String, dynamic>) {
      return <GameScore>[GameScore.fromJson(score)];
    }

    throw const FormatException('Invalid score payload.');
  }

  Future<GameScore?> fetchTeamScore(String roundId) async {
    final rows = await _client
        .from('scores')
        .select()
        .eq('round_id', roundId)
        .isFilter('user_id', null)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return GameScore.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<List<GameScore>> fetchRoundScores(String roundId) async {
    final rows = await _client
        .from('scores')
        .select()
        .eq('round_id', roundId)
        .order('created_at');

    return rows
        .map((row) => GameScore.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}
