class RoomPresence {
  const RoomPresence({
    required this.userId,
    required this.displayName,
    required this.seat,
    required this.ready,
    required this.onlineAt,
  });

  final String userId;
  final String displayName;
  final int seat;
  final bool ready;
  final DateTime onlineAt;

  factory RoomPresence.fromJson(Map<String, dynamic> json) {
    return RoomPresence(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Player',
      seat: json['seat'] as int? ?? 0,
      ready: json['ready'] as bool? ?? false,
      onlineAt:
          DateTime.tryParse(json['onlineAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'displayName': displayName,
      'seat': seat,
      'ready': ready,
      'onlineAt': onlineAt.toIso8601String(),
    };
  }
}
