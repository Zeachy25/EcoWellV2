class AppUser {
  final String id;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? handle;
  final String? bio;
  final String followersCount;
  final int followingCount;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.createdAt,
    this.avatarUrl,
    this.handle,
    this.bio,
    this.followersCount = '0',
    this.followingCount = 0,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'createdAt': createdAt.toIso8601String(),
        'avatarUrl': avatarUrl,
        'handle': handle,
        'bio': bio,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'isVerified': isVerified,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        age: json['age'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        avatarUrl: json['avatarUrl'] as String?,
        handle: json['handle'] as String?,
        bio: json['bio'] as String?,
        followersCount: json['followersCount'] as String? ?? '0',
        followingCount: json['followingCount'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
      );
}