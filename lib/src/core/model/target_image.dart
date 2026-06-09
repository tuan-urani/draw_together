import 'package:draw_together/src/core/model/game_room.dart';

enum TargetDifficulty {
  easy,
  medium,
  hard;

  String get value => name;

  static TargetDifficulty fromValue(String value) {
    return TargetDifficulty.values.firstWhere(
      (difficulty) => difficulty.value == value,
      orElse: () => TargetDifficulty.easy,
    );
  }
}

class TargetImage {
  const TargetImage({
    required this.id,
    required this.storagePath,
    required this.title,
    required this.mode,
    required this.difficulty,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.active,
    required this.createdAt,
    this.checksum,
    this.strokeColor,
    this.player1Color,
    this.player2Color,
  });

  static const defaultStrokeColor = '#1F2937';
  static const defaultPlayer1Color = '#1F2937';
  static const defaultPlayer2Color = '#EF4056';

  final String id;
  final String storagePath;
  final String title;
  final RoomMode mode;
  final TargetDifficulty difficulty;
  final int width;
  final int height;
  final String mimeType;
  final bool active;
  final DateTime createdAt;
  final String? checksum;
  final String? strokeColor;
  final String? player1Color;
  final String? player2Color;

  factory TargetImage.fromJson(Map<String, dynamic> json) {
    return TargetImage(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      title: json['title'] as String,
      mode: RoomMode.fromValue(
        json['mode'] as String? ?? RoomMode.versus.value,
      ),
      difficulty: TargetDifficulty.fromValue(json['difficulty'] as String),
      width: json['width'] as int? ?? 1024,
      height: json['height'] as int? ?? 1024,
      mimeType: json['mime_type'] as String? ?? 'image/png',
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      checksum: json['checksum'] as String?,
      strokeColor: _colorFromJson(json['stroke_color']),
      player1Color: _colorFromJson(json['player1_color']),
      player2Color: _colorFromJson(json['player2_color']),
    );
  }

  static String defaultColorFor({required RoomMode mode, int? seat}) {
    if (mode == RoomMode.versus) return defaultStrokeColor;

    return switch (seat) {
      2 => defaultPlayer2Color,
      _ => defaultPlayer1Color,
    };
  }

  String colorForPlayer({required RoomMode mode, int? seat}) {
    if (mode == RoomMode.versus) {
      return strokeColor ?? defaultStrokeColor;
    }

    return switch (seat) {
      2 => player2Color ?? defaultPlayer2Color,
      _ => player1Color ?? defaultPlayer1Color,
    };
  }

  static String? _colorFromJson(Object? value) {
    if (value is! String) return null;

    final color = value.trim();
    if (color.isEmpty) return null;

    return color;
  }
}
