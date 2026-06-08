import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/room_presence.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/core/repository/target_repository.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';

class RoomLobbyState {
  const RoomLobbyState({
    this.pageState = PageState.initial,
    this.room,
    this.players = const <RoomPlayer>[],
    this.presences = const <RoomPresence>[],
    this.activeRound,
    this.target,
    this.targetUrl,
    this.currentUserId,
    this.remainingMs = 0,
    this.isReady = false,
    this.isStartingRound = false,
    this.roomEndMessage,
    this.errorMessage,
  });

  final PageState pageState;
  final GameRoom? room;
  final List<RoomPlayer> players;
  final List<RoomPresence> presences;
  final GameRound? activeRound;
  final TargetImage? target;
  final String? targetUrl;
  final String? currentUserId;
  final int remainingMs;
  final bool isReady;
  final bool isStartingRound;
  final String? roomEndMessage;
  final String? errorMessage;

  bool get isHost => room != null && currentUserId == room!.hostUserId;

  bool get hasTwoPlayers {
    return players.any((player) => player.seat == 1) &&
        players.any((player) => player.seat == 2);
  }

  bool get allPlayersReady {
    if (!hasTwoPlayers) return false;
    return _isPlayerReady(_playerAtSeat(1)) && _isPlayerReady(_playerAtSeat(2));
  }

  bool get canStartRound {
    return isHost &&
        hasTwoPlayers &&
        allPlayersReady &&
        activeRound == null &&
        !isStartingRound;
  }

  RoomLobbyState copyWith({
    PageState? pageState,
    GameRoom? room,
    List<RoomPlayer>? players,
    List<RoomPresence>? presences,
    GameRound? activeRound,
    TargetImage? target,
    String? targetUrl,
    String? currentUserId,
    int? remainingMs,
    bool? isReady,
    bool? isStartingRound,
    String? roomEndMessage,
    String? errorMessage,
    bool clearActiveRound = false,
    bool clearTarget = false,
    bool clearTargetUrl = false,
    bool clearError = false,
    bool clearRoomEndMessage = false,
  }) {
    return RoomLobbyState(
      pageState: pageState ?? this.pageState,
      room: room ?? this.room,
      players: players ?? this.players,
      presences: presences ?? this.presences,
      activeRound: clearActiveRound ? null : activeRound ?? this.activeRound,
      target: clearTarget ? null : target ?? this.target,
      targetUrl: clearTargetUrl ? null : targetUrl ?? this.targetUrl,
      currentUserId: currentUserId ?? this.currentUserId,
      remainingMs: remainingMs ?? this.remainingMs,
      isReady: isReady ?? this.isReady,
      isStartingRound: isStartingRound ?? this.isStartingRound,
      roomEndMessage: clearRoomEndMessage
          ? null
          : roomEndMessage ?? this.roomEndMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  RoomPlayer? _playerAtSeat(int seat) {
    for (final player in players) {
      if (player.seat == seat) return player;
    }
    return null;
  }

  bool _isPlayerReady(RoomPlayer? player) {
    if (player == null) return false;
    if (room != null && player.userId == room!.hostUserId) return true;

    for (final presence in presences) {
      if (presence.userId == player.userId && presence.ready) return true;
    }
    return false;
  }
}

class RoomLobbyBloc extends Cubit<RoomLobbyState> {
  RoomLobbyBloc(this._roomRepository, this._targetRepository)
    : super(const RoomLobbyState());

  final RoomRepository _roomRepository;
  final TargetRepository _targetRepository;
  RealtimeChannel? _channel;
  String? _connectedRoomId;
  Timer? _roundTimer;
  String? _lastTrackedPresenceSignature;

  Future<void> loadRoom(String roomId) async {
    stopRoundTimer();
    emit(
      state.copyWith(
        pageState: PageState.loading,
        remainingMs: 0,
        isReady: false,
        isStartingRound: false,
        clearActiveRound: true,
        clearTarget: true,
        clearTargetUrl: true,
        clearRoomEndMessage: true,
        clearError: true,
      ),
    );

    try {
      final room = await _roomRepository.fetchRoomById(roomId);
      final players = await _roomRepository.listRoomPlayers(roomId);
      final latestRound = await _roomRepository.fetchLatestRound(roomId);
      final round = latestRound?.status == RoundStatus.drawing
          ? latestRound
          : null;
      final target = round == null
          ? null
          : await _targetRepository.fetchTargetById(round.targetImageId);

      emit(
        state.copyWith(
          pageState: PageState.success,
          room: room,
          players: players,
          activeRound: round,
          target: target,
          targetUrl: target == null
              ? null
              : _targetRepository.publicUrlFor(target),
          currentUserId: _roomRepository.currentUserId,
          remainingMs: round == null ? 0 : _remainingMsFor(round),
          isReady: room.hostUserId == _roomRepository.currentUserId,
          isStartingRound: false,
          clearActiveRound: round == null,
          clearTarget: target == null,
          clearTargetUrl: target == null,
          clearRoomEndMessage: true,
          clearError: true,
        ),
      );

      if (round?.status == RoundStatus.drawing) {
        _startRoundTimer(round!);
      }
      await _connectPresence(room: room, players: players);
    } catch (error) {
      emit(
        state.copyWith(
          pageState: PageState.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> startRound() async {
    final room = state.room;
    if (room == null || state.activeRound != null) return;

    if (!state.isHost) {
      emit(state.copyWith(errorMessage: 'Only the host can start the round.'));
      return;
    }

    if (!state.hasTwoPlayers) {
      emit(state.copyWith(errorMessage: 'Two players are required.'));
      return;
    }

    if (!state.allPlayersReady) {
      emit(state.copyWith(errorMessage: 'Both players must be ready.'));
      return;
    }

    emit(state.copyWith(isStartingRound: true, clearError: true));

    try {
      final target = await _targetRepository.selectRandomActiveTarget(
        mode: room.mode,
      );
      if (target == null) {
        emit(
          state.copyWith(
            isStartingRound: false,
            errorMessage:
                'No active ${room.mode.label} target images available.',
          ),
        );
        return;
      }

      final round = await _roomRepository.createRound(
        room: room,
        target: target,
      );
      final updatedRoom = await _roomRepository.fetchRoomById(room.id);

      emit(
        state.copyWith(
          room: updatedRoom,
          activeRound: round,
          target: target,
          targetUrl: _targetRepository.publicUrlFor(target),
          remainingMs: _remainingMsFor(round),
          isStartingRound: false,
          clearError: true,
        ),
      );

      _startRoundTimer(round);
      await _broadcastRoundStarted(round);
    } catch (error) {
      emit(
        state.copyWith(isStartingRound: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> setReady(bool ready) async {
    final room = state.room;
    if (room == null) return;

    emit(state.copyWith(isReady: ready, clearError: true));
    await _trackPresence(room: room, players: state.players, ready: ready);
  }

  Future<void> leaveRoomFromBack() async {
    final room = state.room;
    if (room == null) return;

    try {
      if (state.isHost) {
        await _roomRepository.finishRoom(room.id);
        await _broadcastRoomClosed(
          'The host left the room. Returning to lobby.',
        );
      }

      await _roomRepository.leaveCurrentPlayerRoom(room.id);
      await disconnectPresence();
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  RoomPresence? presenceForUser(String userId) {
    for (final presence in state.presences) {
      if (presence.userId == userId) return presence;
    }
    return null;
  }

  Future<void> disconnectPresence() async {
    final channel = _channel;
    if (channel == null) return;

    await channel.untrack();
    await _roomRepository.removeChannel(channel);
    _channel = null;
    _connectedRoomId = null;
    _lastTrackedPresenceSignature = null;
  }

  void stopRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = null;
  }

  Future<void> _connectPresence({
    required GameRoom room,
    required List<RoomPlayer> players,
  }) async {
    if (_connectedRoomId == room.id && _channel != null) {
      await _trackPresence(room: room, players: players, ready: state.isReady);
      return;
    }

    await disconnectPresence();

    final channel = _roomRepository.createRoomChannel(room.id);
    _channel = channel;
    _connectedRoomId = room.id;

    channel
        .onBroadcast(
          event: 'round_started',
          callback: (payload) {
            final roundPayload = payload['round'];
            if (roundPayload is Map<String, dynamic>) {
              unawaited(
                _handleRoundStarted(
                  GameRound.fromBroadcastPayload(roundPayload),
                ),
              );
              return;
            }

            unawaited(_loadLatestRound(room.id));
          },
        )
        .onBroadcast(
          event: 'room_closed',
          callback: (payload) {
            final message = payload['message'] as String?;
            emit(
              state.copyWith(
                roomEndMessage:
                    message ?? 'The room was closed. Returning to lobby.',
              ),
            );
          },
        )
        .onPresenceSync((_) {
          _syncPresenceState();
        })
        .onPresenceJoin((_) {
          _syncPresenceState();
          unawaited(_refreshPlayers());
        })
        .onPresenceLeave((_) {
          _syncPresenceState();
          unawaited(_refreshPlayers());
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _trackPresence(
              room: room,
              players: players,
              ready: state.isHost || state.isReady,
            );
            return;
          }

          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            emit(
              state.copyWith(
                errorMessage:
                    error?.toString() ?? 'Could not connect room presence.',
              ),
            );
          }
        });
  }

  Future<void> _trackPresence({
    required GameRoom room,
    required List<RoomPlayer> players,
    required bool ready,
  }) async {
    final channel = _channel;
    final currentUserId = _roomRepository.currentUserId;
    if (channel == null || currentUserId == null) return;

    final player = _currentRoomPlayer(players, currentUserId);
    final presence = RoomPresence(
      userId: currentUserId,
      displayName: player?.displayName ?? 'Player',
      seat: player?.seat ?? 0,
      ready: room.hostUserId == currentUserId || ready,
      onlineAt: DateTime.now(),
    );
    final signature =
        '${presence.userId}|${presence.displayName}|${presence.seat}|${presence.ready}';
    if (_lastTrackedPresenceSignature == signature) {
      _upsertLocalPresence(presence);
      return;
    }

    await channel.track(presence.toJson());
    _lastTrackedPresenceSignature = signature;
    _upsertLocalPresence(presence);
  }

  void _syncPresenceState() {
    final channel = _channel;
    if (channel == null) return;

    final presences = <RoomPresence>[];
    for (final state in channel.presenceState()) {
      for (final presence in state.presences) {
        presences.add(RoomPresence.fromJson(presence.payload));
      }
    }

    emit(state.copyWith(presences: presences));
  }

  Future<void> _refreshPlayers() async {
    final room = state.room;
    if (room == null) return;

    try {
      final players = await _roomRepository.listRoomPlayers(room.id);
      if (isClosed) return;
      emit(state.copyWith(players: players));
    } catch (_) {
      // Presence still provides a fallback while DB state catches up.
    }
  }

  void _upsertLocalPresence(RoomPresence presence) {
    if (isClosed) return;

    final presences = <RoomPresence>[];
    var replaced = false;
    for (final existing in state.presences) {
      if (existing.userId == presence.userId) {
        if (!replaced) presences.add(presence);
        replaced = true;
        continue;
      }
      presences.add(existing);
    }

    if (!replaced) presences.add(presence);
    emit(state.copyWith(presences: presences));
  }

  Future<void> _broadcastRoundStarted(GameRound round) async {
    final channel = _channel;
    if (channel == null) return;

    await channel.sendBroadcastMessage(
      event: 'round_started',
      payload: <String, dynamic>{'round': round.toBroadcastPayload()},
    );
  }

  Future<void> _broadcastRoomClosed(String message) async {
    final channel = _channel;
    if (channel == null) return;

    await channel.sendBroadcastMessage(
      event: 'room_closed',
      payload: <String, dynamic>{
        'type': 'room_closed',
        'roomId': state.room?.id,
        'message': message,
      },
    );
  }

  Future<void> _loadLatestRound(String roomId) async {
    try {
      final round = await _roomRepository.fetchLatestRound(roomId);
      if (round == null || isClosed) return;

      await _handleRoundStarted(round);
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> _handleRoundStarted(GameRound round) async {
    final target = await _targetRepository.fetchTargetById(round.targetImageId);
    if (isClosed) return;

    emit(
      state.copyWith(
        activeRound: round,
        target: target,
        targetUrl: target == null
            ? null
            : _targetRepository.publicUrlFor(target),
        remainingMs: _remainingMsFor(round),
        clearError: true,
      ),
    );

    _startRoundTimer(round);
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

  RoomPlayer? _currentRoomPlayer(List<RoomPlayer> players, String userId) {
    for (final player in players) {
      if (player.userId == userId) return player;
    }
    return null;
  }

  @override
  Future<void> close() async {
    stopRoundTimer();
    await disconnectPresence();
    return super.close();
  }
}
