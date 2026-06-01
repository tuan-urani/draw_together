# Repository & BLoC Mapping

## Repository Pattern
Repositories act as the bridge between Data Sources (API) and the Domain/Business Logic.

```dart
// lib/src/core/repository/auth_repository.dart
class AuthRepository extends Api {
  final AppShared _appShared;
  final IAuthApiUrl _authUrl;

  AuthRepository(this._appShared, this._authUrl);

  Future<void> login(Map<String, dynamic> payload) async {
    final res = await request(
      _authUrl.login,
      Method.post,
      body: payload,
    );
    // Save token, handle data
  }
}
```

## BLoC Implementation
BLoCs use repositories to fetch data and emit states.

```dart
// lib/src/ui/notification/interactor/notification_bloc.dart
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  // Inject Repository if needed
  // final NotificationRepository _repo;

  NotificationBloc() : super(const NotificationState()) {
    on<NotificationInitialized>(_onInitialized);
  }

  Future<void> _onInitialized(event, emit) async {
    emit(state.copyWith(pageState: PageState.loading));
    try {
      // await _repo.fetchNotifications();
      emit(state.copyWith(pageState: PageState.success));
    } catch (e) {
      emit(state.copyWith(pageState: PageState.failure));
    }
  }
}
```
