import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/player_display_name.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> deleteCurrentAccount() async {
    if (currentSession == null) {
      throw const AuthException('Missing authenticated session.');
    }

    try {
      await _client.functions.invoke('delete-account');
    } on FunctionException catch (error) {
      throw AuthException(
        _functionErrorMessage(error),
        statusCode: '${error.status}',
      );
    }

    await signOut();
  }

  Future<User> ensureAnonymousSession({String? displayName}) async {
    final existingUser = currentUser;
    if (existingUser != null) return existingUser;
    final guestName = displayName ?? PlayerDisplayName.randomName();

    final response = await _client.auth.signInAnonymously(
      data: {'display_name': guestName},
    );
    final user = response.user;

    if (user == null) {
      throw const AuthException('Anonymous sign-in did not return a user.');
    }

    return user;
  }

  Future<AuthResponse> signInAnonymously({String? displayName}) {
    final guestName = displayName ?? PlayerDisplayName.randomName();
    return _client.auth.signInAnonymously(data: {'display_name': guestName});
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  String _functionErrorMessage(FunctionException error) {
    final details = error.details;
    if (details is Map<String, dynamic>) {
      final message = details['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (details is String && details.trim().isNotEmpty) {
      return details.trim();
    }

    return error.reasonPhrase ?? 'Could not delete account.';
  }
}
