enum RoomMode {
  coop,
  versus;

  String get value => name;

  String get label {
    switch (this) {
      case RoomMode.coop:
        return 'Co-op';
      case RoomMode.versus:
        return 'Versus';
    }
  }

  static RoomMode fromValue(String value) {
    return RoomMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => RoomMode.coop,
    );
  }
}

enum RoomStatus {
  waiting,
  ready,
  drawing,
  submitting,
  scoring,
  finished,
  expired;

  String get value => name;

  static RoomStatus fromValue(String value) {
    return RoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoomStatus.waiting,
    );
  }
}

class GameRoom {
  const GameRoom({
    required this.id,
    required this.code,
    required this.mode,
    required this.hostUserId,
    required this.status,
    required this.maxPlayers,
    required this.createdAt,
    required this.expiresAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final RoomMode mode;
  final String hostUserId;
  final RoomStatus status;
  final int maxPlayers;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? updatedAt;

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String,
      code: json['code'] as String,
      mode: RoomMode.fromValue(json['mode'] as String),
      hostUserId: json['host_user_id'] as String,
      status: RoomStatus.fromValue(json['status'] as String),
      maxPlayers: json['max_players'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      updatedAt: _dateTimeFromJson(json['updated_at']),
    );
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
