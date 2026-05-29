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
  AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;
}
