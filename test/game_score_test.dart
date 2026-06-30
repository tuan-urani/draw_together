import 'package:flutter_test/flutter_test.dart';

import 'package:draw_together/src/core/model/game_score.dart';

void main() {
  group('GameScore rationale parsing', () {
    test('parses localized rationale object', () {
      final score = GameScore.fromJson(
        _scoreJson(
          rationaleLocalized: <String, Object?>{
            'en': <String>[
              'The roof shape is close.',
              'The windows are missing.',
              'The chimney is off.',
            ],
            'ja': <String>['屋根の形はかなり近いです。', '窓が見当たりません。', '煙突の位置がずれています。'],
            'vi': <String>[
              'Hình mái khá giống.',
              'Thiếu các cửa sổ.',
              'Ống khói bị lệch vị trí.',
            ],
          },
        ),
      );

      expect(score.rationaleForLocale('en'), <String>[
        'The roof shape is close.',
        'The windows are missing.',
        'The chimney is off.',
      ]);
      expect(score.rationaleForLocale('ja'), <String>[
        '屋根の形はかなり近いです。',
        '窓が見当たりません。',
        '煙突の位置がずれています。',
      ]);
      expect(score.rationaleForLocale('vi'), <String>[
        'Hình mái khá giống.',
        'Thiếu các cửa sổ.',
        'Ống khói bị lệch vị trí.',
      ]);
    });

    test('wraps legacy rationale string', () {
      final score = GameScore.fromJson(
        _scoreJson(rationale: 'The drawing misses key proportions.'),
      );

      expect(score.rationaleForLocale('en'), <String>[
        'The drawing misses key proportions.',
      ]);
      expect(score.rationaleForLocale('ja'), <String>[
        'The drawing misses key proportions.',
      ]);
    });
  });
}

Map<String, dynamic> _scoreJson({
  Object? rationale,
  Map<String, Object?>? rationaleLocalized,
}) {
  final rationaleJson = rationale == null
      ? null
      : <String, dynamic>{'rationale': rationale};
  final rationaleLocalizedJson = rationaleLocalized == null
      ? null
      : <String, dynamic>{'rationale_localized': rationaleLocalized};

  return <String, dynamic>{
    'id': 'score-1',
    'round_id': 'round-1',
    'submission_id': 'submission-1',
    'user_id': null,
    'team_score': null,
    'similarity_score': 82,
    'winner': false,
    ...?rationaleJson,
    ...?rationaleLocalizedJson,
    'created_at': DateTime.utc(2026).toIso8601String(),
  };
}
