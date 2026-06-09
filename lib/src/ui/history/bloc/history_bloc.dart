import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/repository/history_repository.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';

class HistoryState {
  const HistoryState({
    this.pageState = PageState.initial,
    this.entries = const <GameHistoryEntry>[],
    this.errorMessage,
  });

  final PageState pageState;
  final List<GameHistoryEntry> entries;
  final String? errorMessage;

  HistoryState copyWith({
    PageState? pageState,
    List<GameHistoryEntry>? entries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      pageState: pageState ?? this.pageState,
      entries: entries ?? this.entries,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class HistoryBloc extends Cubit<HistoryState> {
  HistoryBloc(this._historyRepository) : super(const HistoryState());

  final HistoryRepository _historyRepository;

  Future<void> load() async {
    emit(state.copyWith(pageState: PageState.loading, clearError: true));

    try {
      final entries = await _historyRepository.listHistory();
      emit(
        state.copyWith(
          pageState: PageState.success,
          entries: entries,
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
}
