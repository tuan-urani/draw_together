import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<User> ensureAnonymousSession({String displayName = 'Player'}) async {
    final existingUser = currentUser;
    if (existingUser != null) return existingUser;

    final response = await _client.auth.signInAnonymously(
      data: {'display_name': displayName},
    );
    final user = response.user;

    if (user == null) {
      throw const AuthException('Anonymous sign-in did not return a user.');
    }

    return user;
  }

  Future<AuthResponse> signInAnonymously({String displayName = 'Player'}) {
    return _client.auth.signInAnonymously(data: {'display_name': displayName});
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
