import 'package:flutter_test/flutter_test.dart';

import 'package:draw_together/src/core/model/game_score.dart';

void main() {
  group('GameScore rationale parsing', () {
    test('parses rationale array', () {
      final score = GameScore.fromJson(
        _scoreJson(
          rationale: <String>[
            'The roof shape is close.',
            'The windows are missing.',
          ],
        ),
      );

      expect(score.rationale, <String>[
        'The roof shape is close.',
        'The windows are missing.',
      ]);
    });

    test('wraps legacy rationale string', () {
      final score = GameScore.fromJson(
        _scoreJson(rationale: 'The drawing misses key proportions.'),
      );

      expect(score.rationale, <String>['The drawing misses key proportions.']);
    });
  });
}

Map<String, dynamic> _scoreJson({required Object? rationale}) {
  return <String, dynamic>{
    'id': 'score-1',
    'round_id': 'round-1',
    'submission_id': 'submission-1',
    'user_id': null,
    'team_score': null,
    'similarity_score': 82,
    'winner': false,
    'rationale': rationale,
    'created_at': DateTime.utc(2026).toIso8601String(),
  };
}
