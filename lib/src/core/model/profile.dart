class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.authProvider,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String? authProvider;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Player',
      authProvider: json['auth_provider'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'auth_provider': authProvider,
      'avatar_url': avatarUrl,
    };
  }

  Profile copyWith({
    String? displayName,
    String? authProvider,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      authProvider: authProvider ?? this.authProvider,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
