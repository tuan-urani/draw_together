import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/drawing_stroke_segment.dart';
import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/game_score.dart';
import 'package:draw_together/src/core/model/game_submission.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/core/repository/scoring_repository.dart';
import 'package:draw_together/src/core/repository/submission_repository.dart';
import 'package:draw_together/src/core/repository/target_repository.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';

class DrawingBoardState {
  const DrawingBoardState({
    this.pageState = PageState.initial,
    this.room,
    this.round,
    this.target,
    this.targetUrl,
    this.currentUserId,
    this.currentColorHex = '#333333',
    this.segments = const <DrawingStrokeSegment>[],
    this.submissions = const <GameSubmission>[],
    this.scores = const <GameScore>[],
    this.teamSubmission,
    this.teamScore,
    this.remainingMs = 0,
    this.isRealtimeConnected = false,
    this.isSubmitting = false,
    this.isScoring = false,
    this.errorMessage,
  });

  final PageState pageState;
  final GameRoom? room;
  final GameRound? round;
  final TargetImage? target;
  final String? targetUrl;
  final String? currentUserId;
  final String currentColorHex;
  final List<DrawingStrokeSegment> segments;
  final List<GameSubmission> submissions;
  final List<GameScore> scores;
  final GameSubmission? teamSubmission;
  final GameScore? teamScore;
  final int remainingMs;
  final bool isRealtimeConnected;
  final bool isSubmitting;
  final bool isScoring;
  final String? errorMessage;

  bool get canDraw {
    return pageState == PageState.success &&
        round?.status == RoundStatus.drawing &&
        remainingMs > 0;
  }

  bool get isHost => room != null && currentUserId == room!.hostUserId;

  bool get isVersus => room?.mode == RoomMode.versus;

  bool get isCoop => room?.mode == RoomMode.coop;

  GameSubmission? get currentPlayerSubmission {
    final userId = currentUserId;
    if (userId == null) return null;

    for (final submission in submissions.reversed) {
      if (!submission.isTeamSubmission && submission.userId == userId) {
        return submission;
      }
    }
    return null;
  }

  bool get hasCurrentPlayerSubmitted => currentPlayerSubmission != null;

  GameScore? get currentPlayerScore {
    final userId = currentUserId;
    if (userId == null) return null;

    for (final score in scores) {
      if (score.userId == userId) return score;
    }
    return null;
  }

  GameScore? get opponentScore {
    final userId = currentUserId;
    if (userId == null) return null;

    for (final score in scores) {
      if (score.userId != null && score.userId != userId) return score;
    }
    return null;
  }

  bool get isTie {
    if (!isVersus || scores.length < 2) return false;
    return !scores.any((score) => score.winner);
  }

  bool get hasBothVersusSubmissions {
    return submissions
            .where((submission) => !submission.isTeamSubmission)
            .map((submission) => submission.userId)
            .whereType<String>()
            .toSet()
            .length >=
        2;
  }

  bool get canSubmitTeamCanvas {
    return pageState == PageState.success &&
        isCoop &&
        isHost &&
        remainingMs == 0 &&
        teamSubmission == null &&
        !isSubmitting;
  }

  bool get canSubmitPlayerCanvas {
    return pageState == PageState.success &&
        isVersus &&
        remainingMs == 0 &&
        !hasCurrentPlayerSubmitted &&
        !isSubmitting;
  }

  bool get canScoreRound {
    if (pageState != PageState.success || !isHost || isScoring) {
      return false;
    }

    if (isCoop) return teamSubmission != null && teamScore == null;

    return isVersus && hasBothVersusSubmissions && scores.isEmpty;
  }

  DrawingBoardState copyWith({
    PageState? pageState,
    GameRoom? room,
    GameRound? round,
    TargetImage? target,
    String? targetUrl,
    String? currentUserId,
    String? currentColorHex,
    List<DrawingStrokeSegment>? segments,
    List<GameSubmission>? submissions,
    List<GameScore>? scores,
    GameSubmission? teamSubmission,
    GameScore? teamScore,
    int? remainingMs,
    bool? isRealtimeConnected,
    bool? isSubmitting,
    bool? isScoring,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DrawingBoardState(
      pageState: pageState ?? this.pageState,
      room: room ?? this.room,
      round: round ?? this.round,
      target: target ?? this.target,
      targetUrl: targetUrl ?? this.targetUrl,
      currentUserId: currentUserId ?? this.currentUserId,
      currentColorHex: currentColorHex ?? this.currentColorHex,
      segments: segments ?? this.segments,
      submissions: submissions ?? this.submissions,
      scores: scores ?? this.scores,
      teamSubmission: teamSubmission ?? this.teamSubmission,
      teamScore: teamScore ?? this.teamScore,
      remainingMs: remainingMs ?? this.remainingMs,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isScoring: isScoring ?? this.isScoring,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DrawingBoardBloc extends Cubit<DrawingBoardState> {
  DrawingBoardBloc(
    this._roomRepository,
    this._targetRepository,
    this._submissionRepository,
    this._scoringRepository,
  ) : super(const DrawingBoardState());

  final RoomRepository _roomRepository;
  final TargetRepository _targetRepository;
  final SubmissionRepository _submissionRepository;
  final ScoringRepository _scoringRepository;

  RealtimeChannel? _channel;
  Timer? _roundTimer;
  final Set<String> _receivedSegmentKeys = <String>{};

  Future<void> load(String roomId) async {
    emit(state.copyWith(pageState: PageState.loading, clearError: true));

    try {
      final room = await _roomRepository.fetchRoomById(roomId);
      final players = await _roomRepository.listRoomPlayers(roomId);
      final round = await _roomRepository.fetchLatestRound(roomId);
      if (round == null) {
        emit(
          state.copyWith(
            pageState: PageState.failure,
            errorMessage: 'No active round found.',
          ),
        );
        return;
      }

      final target = await _targetRepository.fetchTargetById(
        round.targetImageId,
      );
      final submissions = await _submissionRepository.listRoundSubmissions(
        round.id,
      );
      final scores = await _scoringRepository.fetchRoundScores(round.id);
      final currentUserId = _roomRepository.currentUserId;

      emit(
        state.copyWith(
          pageState: PageState.success,
          room: room,
          round: round,
          target: target,
          targetUrl: target == null
              ? null
              : _targetRepository.publicUrlFor(target),
          currentUserId: currentUserId,
          currentColorHex: _colorForCurrentPlayer(
            room.mode,
            players,
            currentUserId,
          ),
          submissions: submissions,
          scores: scores,
          teamSubmission: _firstTeamSubmission(submissions),
          teamScore: _teamScore(scores),
          remainingMs: _remainingMsFor(round),
          clearError: true,
        ),
      );

      _startRoundTimer(round);
      await _connectRealtime(roomId);
    } catch (error) {
      emit(
        state.copyWith(
          pageState: PageState.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void addLocalSegment(DrawingStrokeSegment segment) {
    if (!state.canDraw) return;

    _appendSegment(segment);
    if (state.isCoop) {
      unawaited(_broadcastStrokeSegment(segment));
    }
  }

  Future<void> submitTeamCanvas({
    required Uint8List pngBytes,
    required int width,
    required int height,
  }) async {
    final round = state.round;
    if (round == null || !state.canSubmitTeamCanvas) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final submission = await _submissionRepository.uploadTeamSubmission(
        round: round,
        pngBytes: pngBytes,
        width: width,
        height: height,
      );

      await _roomRepository.markRoundSubmitting(round);

      emit(
        state.copyWith(
          teamSubmission: submission,
          isSubmitting: false,
          clearError: true,
        ),
      );

      await _broadcastPlayerSubmitted(submission);
      await scoreRound();
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> submitCurrentPlayerCanvas({
    required Uint8List pngBytes,
    required int width,
    required int height,
  }) async {
    final round = state.round;
    if (round == null || !state.canSubmitPlayerCanvas) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final submission = await _submissionRepository.uploadPlayerSubmission(
        round: round,
        pngBytes: pngBytes,
        width: width,
        height: height,
      );
      final submissions = _upsertSubmission(state.submissions, submission);

      emit(
        state.copyWith(
          submissions: submissions,
          isSubmitting: false,
          clearError: true,
        ),
      );

      await _broadcastPlayerSubmitted(submission);
      unawaited(_scoreVersusIfReady());
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> scoreRound() async {
    final round = state.round;
    if (round == null || !state.canScoreRound) return;

    emit(state.copyWith(isScoring: true, clearError: true));

    try {
      final scores = await _scoringRepository.scoreRoundScores(round.id);
      emit(
        state.copyWith(
          scores: scores,
          teamScore: _teamScore(scores),
          isScoring: false,
          clearError: true,
        ),
      );
      await _broadcastResultReady(scores);
    } catch (error) {
      emit(state.copyWith(isScoring: false, errorMessage: error.toString()));
    }
  }

  Future<void> disconnectRealtime() async {
    final channel = _channel;
    if (channel == null) return;

    await _roomRepository.removeChannel(channel);
    _channel = null;

    if (!isClosed) {
      emit(state.copyWith(isRealtimeConnected: false));
    }
  }

  void stopRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = null;
  }

  Future<void> _connectRealtime(String roomId) async {
    await disconnectRealtime();

    final channel = _roomRepository.createRoomChannel(roomId);
    _channel = channel;

    channel
        .onBroadcast(
          event: 'stroke_segment',
          callback: (payload) {
            if (state.isVersus) return;

            final segment = DrawingStrokeSegment.fromBroadcastPayload(payload);
            if (segment.playerId == state.currentUserId) return;
            _appendSegment(segment);
          },
        )
        .onBroadcast(
          event: 'player_submitted',
          callback: (payload) {
            final submissionPayload = payload['submission'];
            if (submissionPayload is Map<String, dynamic>) {
              final submission = GameSubmission.fromJson(submissionPayload);
              final submissions = _upsertSubmission(
                state.submissions,
                submission,
              );

              emit(
                state.copyWith(
                  submissions: submissions,
                  teamSubmission: submission.isTeamSubmission
                      ? submission
                      : state.teamSubmission,
                ),
              );

              unawaited(_scoreVersusIfReady());
            }
          },
        )
        .onBroadcast(
          event: 'result_ready',
          callback: (payload) {
            final scoresPayload = payload['scores'];
            if (scoresPayload is List<dynamic>) {
              final scores = scoresPayload
                  .whereType<Map<dynamic, dynamic>>()
                  .map(
                    (score) =>
                        GameScore.fromJson(Map<String, dynamic>.from(score)),
                  )
                  .toList(growable: false);

              emit(
                state.copyWith(scores: scores, teamScore: _teamScore(scores)),
              );
              return;
            }

            final scorePayload = payload['score'];
            if (scorePayload is Map<String, dynamic>) {
              final score = GameScore.fromJson(scorePayload);
              emit(
                state.copyWith(scores: <GameScore>[score], teamScore: score),
              );
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            emit(state.copyWith(isRealtimeConnected: true, clearError: true));
            return;
          }

          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            emit(
              state.copyWith(
                isRealtimeConnected: false,
                errorMessage:
                    error?.toString() ?? 'Could not connect drawing realtime.',
              ),
            );
          }
        });
  }

  void _appendSegment(DrawingStrokeSegment segment) {
    if (segment.roundId != state.round?.id || segment.points.length < 2) {
      return;
    }

    if (!_receivedSegmentKeys.add(segment.dedupeKey)) return;

    emit(
      state.copyWith(
        segments: <DrawingStrokeSegment>[...state.segments, segment],
      ),
    );
  }

  Future<void> _broadcastStrokeSegment(DrawingStrokeSegment segment) async {
    final channel = _channel;
    if (channel == null) return;

    await channel.sendBroadcastMessage(
      event: 'stroke_segment',
      payload: segment.toBroadcastPayload(),
    );
  }

  Future<void> _broadcastPlayerSubmitted(GameSubmission submission) async {
    final channel = _channel;
    if (channel == null) return;

    await channel.sendBroadcastMessage(
      event: 'player_submitted',
      payload: <String, dynamic>{
        'type': 'player_submitted',
        'roundId': submission.roundId,
        'playerId': submission.submittedBy,
        'submissionId': submission.id,
        'submission': <String, dynamic>{
          'id': submission.id,
          'round_id': submission.roundId,
          'user_id': submission.userId,
          'submitted_by': submission.submittedBy,
          'is_team_submission': submission.isTeamSubmission,
          'image_path': submission.imagePath,
          'width': submission.width,
          'height': submission.height,
          'created_at': submission.createdAt.toIso8601String(),
        },
      },
    );
  }

  Future<void> _broadcastResultReady(List<GameScore> scores) async {
    final channel = _channel;
    if (channel == null || scores.isEmpty) return;

    final firstScore = scores.first;

    await channel.sendBroadcastMessage(
      event: 'result_ready',
      payload: <String, dynamic>{
        'type': 'result_ready',
        'roundId': firstScore.roundId,
        'resultId': firstScore.id,
        'score': _scorePayload(firstScore),
        'scores': scores.map(_scorePayload).toList(growable: false),
      },
    );
  }

  Map<String, dynamic> _scorePayload(GameScore score) {
    return <String, dynamic>{
      'id': score.id,
      'round_id': score.roundId,
      'submission_id': score.submissionId,
      'user_id': score.userId,
      'team_score': score.teamScore,
      'similarity_score': score.similarityScore,
      'winner': score.winner,
      'created_at': score.createdAt.toIso8601String(),
    };
  }

  Future<void> _scoreVersusIfReady() async {
    if (!state.canScoreRound || !state.isVersus) return;
    await scoreRound();
  }

  void _startRoundTimer(GameRound round) {
    stopRoundTimer();
    _updateRoundRemaining(round);
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRoundRemaining(round);
    });
  }

  void _updateRoundRemaining(GameRound round) {
    final remainingMs = _remainingMsFor(round);
    if (isClosed) return;

    emit(state.copyWith(remainingMs: remainingMs));
    if (remainingMs == 0) stopRoundTimer();
  }

  int _remainingMsFor(GameRound round) {
    final startedAt = round.startedAt;
    if (startedAt == null) return round.durationMs;

    final elapsedMs = DateTime.now()
        .toUtc()
        .difference(startedAt.toUtc())
        .inMilliseconds;
    final remainingMs = round.durationMs - elapsedMs;
    return remainingMs < 0 ? 0 : remainingMs;
  }

  String _colorForCurrentPlayer(
    RoomMode mode,
    List<RoomPlayer> players,
    String? userId,
  ) {
    if (mode == RoomMode.versus) return '#1F2937';

    final seat = players
        .where((player) => player.userId == userId)
        .map((player) => player.seat)
        .firstOrNull;

    return switch (seat) {
      1 => '#1F2937',
      2 => '#EF4056',
      _ => '#1F2937',
    };
  }

  GameSubmission? _firstTeamSubmission(List<GameSubmission> submissions) {
    for (final submission in submissions) {
      if (submission.isTeamSubmission) return submission;
    }
    return null;
  }

  GameScore? _teamScore(List<GameScore> scores) {
    for (final score in scores) {
      if (score.userId == null) return score;
    }
    return null;
  }

  List<GameSubmission> _upsertSubmission(
    List<GameSubmission> submissions,
    GameSubmission submission,
  ) {
    final next = <GameSubmission>[];
    var replaced = false;

    for (final existing in submissions) {
      final sameSubmission = existing.id == submission.id;
      final samePlayerSubmission =
          !submission.isTeamSubmission &&
          !existing.isTeamSubmission &&
          existing.userId == submission.userId;
      final sameTeamSubmission =
          submission.isTeamSubmission && existing.isTeamSubmission;

      if (sameSubmission || samePlayerSubmission || sameTeamSubmission) {
        if (!replaced) next.add(submission);
        replaced = true;
        continue;
      }

      next.add(existing);
    }

    if (!replaced) next.add(submission);
    return List<GameSubmission>.unmodifiable(next);
  }

  @override
  Future<void> close() async {
    stopRoundTimer();
    await disconnectRealtime();
    return super.close();
  }
}
