import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/joinable_room.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';

class RoomBrowserState {
  const RoomBrowserState({
    required this.mode,
    this.pageState = PageState.initial,
    this.rooms = const <JoinableRoom>[],
    this.activeRoom,
    this.errorMessage,
    this.isCreatingRoom = false,
    this.joiningRoomId,
  });

  final RoomMode mode;
  final PageState pageState;
  final List<JoinableRoom> rooms;
  final GameRoom? activeRoom;
  final String? errorMessage;
  final bool isCreatingRoom;
  final String? joiningRoomId;

  bool get isJoiningRoom => joiningRoomId != null;

  RoomBrowserState copyWith({
    PageState? pageState,
    List<JoinableRoom>? rooms,
    GameRoom? activeRoom,
    String? errorMessage,
    bool? isCreatingRoom,
    String? joiningRoomId,
    bool clearError = false,
    bool clearActiveRoom = false,
    bool clearJoiningRoom = false,
  }) {
    return RoomBrowserState(
      mode: mode,
      pageState: pageState ?? this.pageState,
      rooms: rooms ?? this.rooms,
      activeRoom: clearActiveRoom ? null : activeRoom ?? this.activeRoom,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isCreatingRoom: isCreatingRoom ?? this.isCreatingRoom,
      joiningRoomId: clearJoiningRoom
          ? null
          : joiningRoomId ?? this.joiningRoomId,
    );
  }
}

class RoomBrowserBloc extends Cubit<RoomBrowserState> {
  RoomBrowserBloc(this._roomRepository, RoomMode mode)
    : super(RoomBrowserState(mode: mode));

  final RoomRepository _roomRepository;

  Future<void> loadRooms() async {
    emit(
      state.copyWith(
        pageState: PageState.loading,
        clearError: true,
        clearActiveRoom: true,
      ),
    );

    try {
      final rooms = await _roomRepository.listJoinableRooms(mode: state.mode);
      emit(
        state.copyWith(
          pageState: PageState.success,
          rooms: rooms,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          pageState: PageState.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createRoom() async {
    emit(
      state.copyWith(
        isCreatingRoom: true,
        clearError: true,
        clearActiveRoom: true,
      ),
    );

    try {
      final room = await _roomRepository.createRoom(mode: state.mode);
      emit(
        state.copyWith(
          activeRoom: room,
          isCreatingRoom: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isCreatingRoom: false,
          errorMessage: _roomActionErrorMessage(error),
        ),
      );
    }
  }

  Future<void> joinRoom(String roomId) async {
    emit(
      state.copyWith(
        joiningRoomId: roomId,
        clearError: true,
        clearActiveRoom: true,
      ),
    );

    try {
      final room = await _roomRepository.joinRoomById(roomId);
      emit(
        state.copyWith(
          activeRoom: room,
          clearJoiningRoom: true,
          clearError: true,
        ),
      );
    } catch (error) {
      final rooms = await _refreshRoomsAfterFailedJoin();
      emit(
        state.copyWith(
          rooms: rooms,
          clearJoiningRoom: true,
          errorMessage: _roomActionErrorMessage(error),
        ),
      );
    }
  }

  void clearActiveRoom() {
    emit(state.copyWith(clearActiveRoom: true));
  }

  Future<List<JoinableRoom>> _refreshRoomsAfterFailedJoin() async {
    try {
      return _roomRepository.listJoinableRooms(mode: state.mode);
    } catch (_) {
      return state.rooms;
    }
  }

  String _roomActionErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('Room expired')) {
      return 'Room expired. Pick another room.';
    }

    if (message.contains('Room is full') || message.contains('23505')) {
      return 'This room is already full.';
    }

    if (message.contains('Room not found') ||
        message.contains('Results contain 0 rows')) {
      return 'Room not found.';
    }

    return message;
  }
}
