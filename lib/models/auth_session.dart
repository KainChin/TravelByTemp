class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      id: '${user['id']}',
      username: user['username'] as String,
      email: user['email'] as String,
      fullName: user['fullName'] as String,
      role: user['role'] as String,
    );
  }
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: DateTime.tryParse('${json['expiresAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      user: AuthUser.fromJson(json),
    );
  }
}
