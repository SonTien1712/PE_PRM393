class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int id;
  final String username;
  final String displayName;

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as int,
    username: map['username'] as String,
    displayName: map['display_name'] as String,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'username': username,
    'display_name': displayName,
  };
}
