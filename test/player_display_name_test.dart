import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:draw_together/src/core/model/player_display_name.dart';

void main() {
  test('randomName returns player with a three digit suffix', () {
    final name = PlayerDisplayName.randomName(random: Random(7));

    expect(name, matches(RegExp(r'^player\d{3}$')));
  });
}
