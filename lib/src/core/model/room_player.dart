class RoomPlayer {
  const RoomPlayer({
    required this.roomId,
    required this.userId,
    required this.seat,
    required this.joinedAt,
    this.leftAt,
    this.displayName,
  });

  final String roomId;
  final String userId;
  final int seat;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? displayName;

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;

    return RoomPlayer(
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      seat: json['seat'] as int,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: _dateTimeFromJson(json['left_at']),
      displayName: profileMap?['display_name'] as String?,
    );
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
