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
  });

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
    );
  }
}
