import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> ensureCurrentProfile({String displayName = 'Player'}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Missing authenticated user.');
    }

    final existingProfile = await fetchProfile(user.id);
    if (existingProfile != null) return existingProfile;

    return upsertProfile(
      Profile(
        id: user.id,
        displayName: _metadataDisplayName(user) ?? displayName,
        authProvider: user.appMetadata['provider'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      ),
    );
  }

  Future<Profile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return fetchProfile(user.id);
  }

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Profile> upsertProfile(Profile profile) async {
    final row = await _client
        .from('profiles')
        .upsert(profile.toUpsertJson())
        .select()
        .single();

    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Profile> updateDisplayName(String displayName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Missing authenticated user.');
    }

    final row = await _client
        .from('profiles')
        .update({'display_name': displayName.trim()})
        .eq('id', user.id)
        .select()
        .single();

    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  String? _metadataDisplayName(User user) {
    final value = user.userMetadata?['display_name'];
    if (value is! String) return null;

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
