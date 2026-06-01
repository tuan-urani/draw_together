import 'package:draw_together/src/core/model/game_room.dart';

enum RoundStatus {
  pending,
  drawing,
  submitting,
  scoring,
  scored,
  failed;

  String get value => name;

  static RoundStatus fromValue(String value) {
    return RoundStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoundStatus.pending,
    );
  }
}

class GameRound {
  const GameRound({
    required this.id,
    required this.roomId,
    required this.mode,
    required this.targetImageId,
    required this.status,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String roomId;
  final RoomMode mode;
  final String targetImageId;
  final RoundStatus status;
  final int durationMs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory GameRound.fromJson(Map<String, dynamic> json) {
    return GameRound(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      mode: RoomMode.fromValue(json['mode'] as String),
      targetImageId: json['target_image_id'] as String,
      status: RoundStatus.fromValue(json['status'] as String),
      durationMs: json['duration_ms'] as int? ?? 60000,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      startedAt: _dateTimeFromJson(json['started_at']),
      endedAt: _dateTimeFromJson(json['ended_at']),
    );
  }

  factory GameRound.fromBroadcastPayload(Map<String, dynamic> json) {
    return GameRound(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      mode: RoomMode.fromValue(json['mode'] as String),
      targetImageId: json['targetImageId'] as String,
      status: RoundStatus.fromValue(json['status'] as String),
      durationMs: json['durationMs'] as int? ?? 60000,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      startedAt: _dateTimeFromJson(json['startedAt']),
      endedAt: _dateTimeFromJson(json['endedAt']),
    );
  }

  Map<String, dynamic> toBroadcastPayload() {
    return <String, dynamic>{
      'id': id,
      'roomId': roomId,
      'mode': mode.value,
      'targetImageId': targetImageId,
      'status': status.value,
      'durationMs': durationMs,
      'startedAt': startedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
