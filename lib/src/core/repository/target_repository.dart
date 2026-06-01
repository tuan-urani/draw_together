import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/target_image.dart';

class TargetRepository {
  TargetRepository(this._client);

  final SupabaseClient _client;

  Future<List<TargetImage>> listActiveTargets({required RoomMode mode}) async {
    final rows = await _client
        .from('target_images')
        .select()
        .eq('active', true)
        .eq('mode', mode.value)
        .order('created_at');

    return rows
        .map((row) => TargetImage.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<TargetImage?> fetchTargetById(String targetId) async {
    final rows = await _client
        .from('target_images')
        .select()
        .eq('id', targetId)
        .limit(1);

    if (rows.isEmpty) return null;
    return TargetImage.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<TargetImage?> selectRandomActiveTarget({
    required RoomMode mode,
  }) async {
    final targets = await listActiveTargets(mode: mode);
    if (targets.isEmpty) return null;

    return targets[Random.secure().nextInt(targets.length)];
  }

  String publicUrlFor(TargetImage target) {
    return _client.storage.from('targets').getPublicUrl(target.storagePath);
  }
}
