import 'package:flutter_test/flutter_test.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/target_image.dart';

void main() {
  group('TargetImage color metadata', () {
    test('uses versus stroke color when present', () {
      final target = _target(strokeColor: '#0095FF');

      expect(target.colorForPlayer(mode: RoomMode.versus), '#0095FF');
    });

    test('uses co-op player colors by seat', () {
      final target = _target(player1Color: '#123456', player2Color: '#ABCDEF');

      expect(target.colorForPlayer(mode: RoomMode.coop, seat: 1), '#123456');
      expect(target.colorForPlayer(mode: RoomMode.coop, seat: 2), '#ABCDEF');
    });

    test('falls back to legacy colors when metadata is missing', () {
      final target = _target();

      expect(
        target.colorForPlayer(mode: RoomMode.versus),
        TargetImage.defaultStrokeColor,
      );
      expect(
        target.colorForPlayer(mode: RoomMode.coop, seat: 1),
        TargetImage.defaultPlayer1Color,
      );
      expect(
        target.colorForPlayer(mode: RoomMode.coop, seat: 2),
        TargetImage.defaultPlayer2Color,
      );
    });
  });
}

TargetImage _target({
  String? strokeColor,
  String? player1Color,
  String? player2Color,
}) {
  return TargetImage(
    id: 'target-1',
    storagePath: 'versus/easy/target-1.png',
    title: 'Target',
    mode: RoomMode.versus,
    difficulty: TargetDifficulty.easy,
    width: 1024,
    height: 1024,
    mimeType: 'image/png',
    active: true,
    createdAt: DateTime.utc(2026),
    strokeColor: strokeColor,
    player1Color: player1Color,
    player2Color: player2Color,
  );
}
