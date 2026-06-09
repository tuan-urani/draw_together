import 'dart:math';

class PlayerDisplayName {
  const PlayerDisplayName._();

  static String randomName({Random? random}) {
    final suffix = (random ?? Random.secure()).nextInt(1000);
    return 'player${suffix.toString().padLeft(3, '0')}';
  }
}
