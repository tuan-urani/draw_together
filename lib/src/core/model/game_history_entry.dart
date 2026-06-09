import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_score.dart';
import 'package:draw_together/src/core/model/game_submission.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';

class GameHistoryEntry {
  const GameHistoryEntry({
    required this.room,
    required this.round,
    required this.target,
    required this.targetUrl,
    required this.submissions,
    required this.scores,
    required this.players,
    required this.currentUserId,
  });

  final GameRoom room;
  final GameRound round;
  final TargetImage target;
  final String targetUrl;
  final List<GameSubmission> submissions;
  final List<GameScore> scores;
  final List<RoomPlayer> players;
  final String currentUserId;

  bool get isCoop => room.mode == RoomMode.coop;

  bool get isVersus => room.mode == RoomMode.versus;

  GameScore? get teamScore {
    for (final score in scores) {
      if (score.userId == null) return score;
    }
    return scores.isEmpty ? null : scores.first;
  }

  GameScore? get currentUserScore {
    for (final score in scores) {
      if (score.userId == currentUserId) return score;
    }
    return null;
  }

  GameScore? get opponentScore {
    for (final score in scores) {
      if (score.userId != null && score.userId != currentUserId) return score;
    }
    return null;
  }

  GameSubmission? get teamSubmission {
    for (final submission in submissions.reversed) {
      if (submission.isTeamSubmission) return submission;
    }
    return null;
  }

  GameSubmission? get currentUserSubmission {
    for (final submission in submissions.reversed) {
      if (!submission.isTeamSubmission && submission.userId == currentUserId) {
        return submission;
      }
    }
    return null;
  }

  GameSubmission? get opponentSubmission {
    for (final submission in submissions.reversed) {
      if (!submission.isTeamSubmission &&
          submission.userId != null &&
          submission.userId != currentUserId) {
        return submission;
      }
    }
    return null;
  }

  RoomPlayer? get currentPlayer {
    for (final player in players) {
      if (player.userId == currentUserId) return player;
    }
    return null;
  }

  List<RoomPlayer> get otherPlayers {
    return players
        .where((player) => player.userId != currentUserId)
        .toList(growable: false);
  }

  String get partnerName {
    final names = otherPlayers
        .map((player) => player.displayName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) return '';
    return names.join(', ');
  }

  int? get displayScore {
    final score = isCoop ? teamScore : currentUserScore;
    if (score == null) return null;
    return score.teamScore ?? score.similarityScore;
  }
}
