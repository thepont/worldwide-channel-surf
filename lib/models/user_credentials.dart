/// Model for storing VPN credentials
class UserCredentials {
  final String username;
  final String password;

  const UserCredentials({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }

  factory UserCredentials.fromMap(Map<String, dynamic> map) {
    return UserCredentials(
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }
}
