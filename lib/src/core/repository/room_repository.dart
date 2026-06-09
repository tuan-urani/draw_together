import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/joinable_room.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';

class RoomRepository {
  RoomRepository(this._client);

  final SupabaseClient _client;

  Future<GameRoom> createRoom({required RoomMode mode}) async {
    final user = _requireUser();
    late GameRoom room;

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateRoomCode();
      final expiresAt = DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 60))
          .toIso8601String();

      try {
        final roomRow = await _client
            .from('rooms')
            .insert({
              'code': code,
              'mode': mode.value,
              'host_user_id': user.id,
              'expires_at': expiresAt,
            })
            .select()
            .single();

        room = GameRoom.fromJson(Map<String, dynamic>.from(roomRow));

        await _client.from('room_players').insert({
          'room_id': room.id,
          'user_id': user.id,
          'seat': 1,
        });

        return room;
      } on PostgrestException catch (error) {
        final isDuplicateCode = error.code == '23505';
        if (!isDuplicateCode || attempt == 4) rethrow;
      }
    }

    throw const PostgrestException(message: 'Could not create room.');
  }

  Future<GameRoom> joinRoomByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final room = await fetchRoomByCode(normalizedCode);
    return joinRoomById(room.id);
  }

  Future<GameRoom> joinRoomById(String roomId) async {
    _requireUser();
    final row = await _client.rpc(
      'join_room',
      params: {'target_room_id': roomId},
    );

    return GameRoom.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<List<JoinableRoom>> listJoinableRooms({required RoomMode mode}) async {
    _requireUser();
    final rows = await _client.rpc(
      'list_joinable_rooms',
      params: {'target_mode': mode.value},
    );

    return (rows as List<dynamic>)
        .map((row) => JoinableRoom.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<GameRoom> fetchRoomByCode(String code) async {
    final row = await _client
        .from('rooms')
        .select()
        .eq('code', code.trim().toUpperCase())
        .single();
    return GameRoom.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GameRoom> fetchRoomById(String roomId) async {
    final row = await _client.from('rooms').select().eq('id', roomId).single();
    return GameRoom.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<RoomPlayer>> listRoomPlayers(String roomId) async {
    final rows = await _client
        .from('room_players')
        .select(
          'room_id,user_id,seat,joined_at,left_at,profiles(display_name,avatar_url)',
        )
        .eq('room_id', roomId)
        .isFilter('left_at', null)
        .order('seat');

    return rows
        .map((row) => RoomPlayer.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<GameRound?> fetchLatestRound(String roomId) async {
    final rows = await _client
        .from('rounds')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return GameRound.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<GameRound> createRound({
    required GameRoom room,
    required TargetImage target,
    int durationMs = 60000,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final roundRow = await _client
        .from('rounds')
        .insert({
          'room_id': room.id,
          'mode': room.mode.value,
          'target_image_id': target.id,
          'status': RoundStatus.drawing.value,
          'started_at': startedAt.toIso8601String(),
          'duration_ms': durationMs,
        })
        .select()
        .single();

    await _client
        .from('rooms')
        .update({'status': RoomStatus.drawing.value})
        .eq('id', room.id);

    return GameRound.fromJson(Map<String, dynamic>.from(roundRow));
  }

  Future<void> markRoundSubmitting(GameRound round) async {
    final endedAt = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('rounds')
        .update({'status': RoundStatus.submitting.value, 'ended_at': endedAt})
        .eq('id', round.id);

    await _client
        .from('rooms')
        .update({'status': RoomStatus.submitting.value})
        .eq('id', round.roomId);
  }

  Future<void> finishRoom(String roomId) async {
    await _client
        .from('rooms')
        .update({'status': RoomStatus.finished.value})
        .eq('id', roomId);
  }

  Future<void> leaveCurrentPlayerRoom(String roomId) async {
    final user = _requireUser();
    await _client
        .from('room_players')
        .update({'left_at': DateTime.now().toUtc().toIso8601String()})
        .eq('room_id', roomId)
        .eq('user_id', user.id)
        .isFilter('left_at', null);
  }

  Future<void> failRoundAndFinishRoom({
    required String roomId,
    required String roundId,
  }) async {
    final endedAt = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('rounds')
        .update({'status': RoundStatus.failed.value, 'ended_at': endedAt})
        .eq('id', roundId);

    await finishRoom(roomId);
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  RealtimeChannel createRoomChannel(String roomId) {
    final userId = _requireUser().id;
    return _client.channel(
      'room:$roomId',
      opts: RealtimeChannelConfig(key: userId, enabled: true),
    );
  }

  Future<String> removeChannel(RealtimeChannel channel) {
    return _client.removeChannel(channel);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Missing authenticated user.');
    }
    return user;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
