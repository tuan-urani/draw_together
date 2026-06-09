import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/profile.dart';
import 'package:draw_together/src/core/repository/history_repository.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';

class HomeState {
  const HomeState({
    this.pageState = PageState.initial,
    this.profile,
    this.activeRoom,
    this.errorMessage,
    this.isSaving = false,
    this.isRoomActionLoading = false,
    this.recentGames = const <GameHistoryEntry>[],
    this.isRecentGamesLoading = true,
  });

  final PageState pageState;
  final Profile? profile;
  final GameRoom? activeRoom;
  final String? errorMessage;
  final bool isSaving;
  final bool isRoomActionLoading;
  final List<GameHistoryEntry> recentGames;
  final bool isRecentGamesLoading;

  HomeState copyWith({
    PageState? pageState,
    Profile? profile,
    GameRoom? activeRoom,
    String? errorMessage,
    bool? isSaving,
    bool? isRoomActionLoading,
    List<GameHistoryEntry>? recentGames,
    bool? isRecentGamesLoading,
    bool clearError = false,
    bool clearActiveRoom = false,
  }) {
    return HomeState(
      pageState: pageState ?? this.pageState,
      profile: profile ?? this.profile,
      activeRoom: clearActiveRoom ? null : activeRoom ?? this.activeRoom,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
      isRoomActionLoading: isRoomActionLoading ?? this.isRoomActionLoading,
      recentGames: recentGames ?? this.recentGames,
      isRecentGamesLoading: isRecentGamesLoading ?? this.isRecentGamesLoading,
    );
  }
}

class HomeBloc extends Cubit<HomeState> {
  HomeBloc(
    this._profileRepository,
    this._roomRepository,
    this._historyRepository,
  ) : super(const HomeState());

  final ProfileRepository _profileRepository;
  final RoomRepository _roomRepository;
  final HistoryRepository _historyRepository;

  Future<void> loadProfile() async {
    emit(state.copyWith(pageState: PageState.loading, clearError: true));

    try {
      final profile = await _profileRepository.ensureCurrentProfile();
      emit(
        state.copyWith(
          pageState: PageState.success,
          profile: profile,
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

  Future<void> loadRecentGames() async {
    emit(state.copyWith(isRecentGamesLoading: true));

    try {
      final recentGames = await _historyRepository.listHistory(limit: 3);
      emit(
        state.copyWith(recentGames: recentGames, isRecentGamesLoading: false),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isRecentGamesLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty || trimmedName.length > 40) {
      emit(
        state.copyWith(
          errorMessage: 'Display name must be between 1 and 40 characters.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final profile = await _profileRepository.updateDisplayName(trimmedName);
      emit(
        state.copyWith(
          pageState: PageState.success,
          profile: profile,
          isSaving: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }

  Future<void> updateAvatar(String avatarAsset) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final profile = await _profileRepository.updateAvatarUrl(avatarAsset);
      emit(
        state.copyWith(
          pageState: PageState.success,
          profile: profile,
          isSaving: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }

  Future<void> createRoom(RoomMode mode) async {
    emit(
      state.copyWith(
        isRoomActionLoading: true,
        clearError: true,
        clearActiveRoom: true,
      ),
    );

    try {
      final room = await _roomRepository.createRoom(mode: mode);
      emit(
        state.copyWith(
          activeRoom: room,
          isRoomActionLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isRoomActionLoading: false,
          errorMessage: _roomActionErrorMessage(error),
        ),
      );
    }
  }

  Future<void> joinRoom(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.length < 4) {
      emit(state.copyWith(errorMessage: 'Enter a valid room code.'));
      return;
    }

    emit(
      state.copyWith(
        isRoomActionLoading: true,
        clearError: true,
        clearActiveRoom: true,
      ),
    );

    try {
      final room = await _roomRepository.joinRoomByCode(normalizedCode);
      emit(
        state.copyWith(
          activeRoom: room,
          isRoomActionLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isRoomActionLoading: false,
          errorMessage: _roomActionErrorMessage(error),
        ),
      );
    }
  }

  void clearActiveRoom() {
    emit(state.copyWith(clearActiveRoom: true));
  }

  String _roomActionErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('duplicate key') || message.contains('23505')) {
      return 'This room is already full or you already joined.';
    }

    if (message.contains('Results contain 0 rows')) {
      return 'Room not found.';
    }

    return message;
  }
}
