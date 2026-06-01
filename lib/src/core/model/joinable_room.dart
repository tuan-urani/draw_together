import 'package:draw_together/src/core/model/game_room.dart';

class JoinableRoom {
  const JoinableRoom({required this.room, required this.playerCount});

  final GameRoom room;
  final int playerCount;

  factory JoinableRoom.fromJson(Map<String, dynamic> json) {
    return JoinableRoom(
      room: GameRoom.fromJson(<String, dynamic>{
        'id': json['room_id'],
        'code': json['code'],
        'mode': json['mode'],
        'host_user_id': json['host_user_id'],
        'status': json['status'],
        'max_players': json['max_players'],
        'created_at': json['created_at'],
        'expires_at': json['expires_at'],
      }),
      playerCount: json['player_count'] as int? ?? 0,
    );
  }
}
