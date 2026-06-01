# Auth BLoC Full Implementation

## **Events (Equatable)**

```dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutPressed extends AuthEvent {
  const AuthLogoutPressed();
}
```

## **States (Equatable)**

```dart
enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? message;

  const AuthState({
    required this.status,
    this.user,
    this.message,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}
```

## **BLoC Implementation**

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthState.initial()) {
    on<AuthLoginSubmitted>(_onLogin);
    on<AuthLogoutPressed>(_onLogout);
  }

  Future<void> _onLogin(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _repository.login(event.email, event.password);

    switch (result) {
      case Success(value: final user):
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      case FailureResult(failure: final failure):
        emit(state.copyWith(status: AuthStatus.failure, message: failure.message));
    }
  }

  Future<void> _onLogout(AuthLogoutPressed event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }
}
```
