import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_submission.dart';

class SubmissionRepository {
  SubmissionRepository(this._client);

  final SupabaseClient _client;

  Future<GameSubmission> uploadTeamSubmission({
    required GameRound round,
    required Uint8List pngBytes,
    required int width,
    required int height,
  }) async {
    final user = _requireUser();
    final imagePath = '${user.id}/${round.id}/${_submissionFileName()}.png';

    await _client.storage
        .from('submissions')
        .uploadBinary(
          imagePath,
          pngBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );

    final row = await _client
        .from('submissions')
        .insert({
          'round_id': round.id,
          'submitted_by': user.id,
          'is_team_submission': true,
          'image_path': imagePath,
          'width': width,
          'height': height,
        })
        .select()
        .single();

    return GameSubmission.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GameSubmission> uploadPlayerSubmission({
    required GameRound round,
    required Uint8List pngBytes,
    required int width,
    required int height,
  }) async {
    final user = _requireUser();
    final imagePath = '${user.id}/${round.id}/${_submissionFileName()}.png';

    await _client.storage
        .from('submissions')
        .uploadBinary(
          imagePath,
          pngBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );

    final row = await _client
        .from('submissions')
        .insert({
          'round_id': round.id,
          'user_id': user.id,
          'submitted_by': user.id,
          'is_team_submission': false,
          'image_path': imagePath,
          'width': width,
          'height': height,
        })
        .select()
        .single();

    return GameSubmission.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<GameSubmission>> listRoundSubmissions(String roundId) async {
    final rows = await _client
        .from('submissions')
        .select()
        .eq('round_id', roundId)
        .order('created_at');

    return rows
        .map((row) => GameSubmission.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> signedUrlFor(GameSubmission submission) {
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

  String _submissionFileName() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '$timestamp-$random';
  }
}
