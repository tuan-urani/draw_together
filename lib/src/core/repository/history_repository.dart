import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_score.dart';
import 'package:draw_together/src/core/model/game_submission.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';

class HistoryRepository {
  HistoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<GameHistoryEntry>> listHistory() async {
    final user = _requireUser();
    final playerRows = await _client
        .from('room_players')
        .select('room_id')
        .eq('user_id', user.id);

    final roomIds = playerRows
        .map((row) => row['room_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    if (roomIds.isEmpty) return const <GameHistoryEntry>[];

    final rounds = await _client
        .from('rounds')
        .select('*, rooms(*), target_images(*)')
        .filter('room_id', 'in', _inFilter(roomIds))
        .eq('status', RoundStatus.scored.value)
        .order('created_at', ascending: false);

    if (rounds.isEmpty) return const <GameHistoryEntry>[];

    final roundIds = rounds
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList(growable: false);

    final scores = await _client
        .from('scores')
        .select()
        .filter('round_id', 'in', _inFilter(roundIds))
        .order('created_at');
    final submissions = await _client
        .from('submissions')
        .select()
        .filter('round_id', 'in', _inFilter(roundIds))
        .order('created_at');
    final players = await _client
        .from('room_players')
        .select(
          'room_id,user_id,seat,joined_at,left_at,profiles(display_name,avatar_url)',
        )
        .filter('room_id', 'in', _inFilter(roomIds))
        .order('seat');

    final scoresByRound = <String, List<GameScore>>{};
    for (final row in scores) {
      final score = GameScore.fromJson(Map<String, dynamic>.from(row));
      scoresByRound.putIfAbsent(score.roundId, () => <GameScore>[]).add(score);
    }

    final submissionsByRound = <String, List<GameSubmission>>{};
    for (final row in submissions) {
      final submission = GameSubmission.fromJson(
        Map<String, dynamic>.from(row),
      );
      submissionsByRound
          .putIfAbsent(submission.roundId, () => <GameSubmission>[])
          .add(submission);
    }

    final playersByRoom = <String, List<RoomPlayer>>{};
    for (final row in players) {
      final player = RoomPlayer.fromJson(Map<String, dynamic>.from(row));
      playersByRoom
          .putIfAbsent(player.roomId, () => <RoomPlayer>[])
          .add(player);
    }

    return rounds
        .map((row) {
          final json = Map<String, dynamic>.from(row);
          final round = GameRound.fromJson(json);
          final room = GameRoom.fromJson(
            Map<String, dynamic>.from(json['rooms'] as Map),
          );
          final target = TargetImage.fromJson(
            Map<String, dynamic>.from(json['target_images'] as Map),
          );

          return GameHistoryEntry(
            room: room,
            round: round,
            target: target,
            targetUrl: _client.storage
                .from('targets')
                .getPublicUrl(target.storagePath),
            submissions:
                submissionsByRound[round.id] ?? const <GameSubmission>[],
            scores: scoresByRound[round.id] ?? const <GameScore>[],
            players: playersByRoom[room.id] ?? const <RoomPlayer>[],
            currentUserId: user.id,
          );
        })
        .toList(growable: false);
  }

  Future<String> signedSubmissionUrl(GameSubmission submission) {
    return _client.storage
        .from('submissions')
        .createSignedUrl(submission.imagePath, 60 * 10);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Missing authenticated user.');
    }
    return user;
  }

  String _inFilter(List<String> values) {
    return '(${values.map((value) => '"$value"').join(',')})';
  }
}
