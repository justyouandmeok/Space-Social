class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.passwordHash,
    required this.salt,
    this.avatarPath = '',
    this.bio = '',
    this.website = '',
    this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final String name;
  final String passwordHash;
  final String salt;
  final String avatarPath;
  final String bio;
  final String website;
  final DateTime? createdAt;

  UserAccount copyWith({
    String? email,
    String? username,
    String? name,
    String? passwordHash,
    String? salt,
    String? avatarPath,
    String? bio,
    String? website,
  }) {
    return UserAccount(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'name': name,
        'passwordHash': passwordHash,
        'salt': salt,
        'avatarPath': avatarPath,
        'bio': bio,
        'website': website,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        id: j['id'] as String,
        email: j['email'] as String? ?? '',
        username: j['username'] as String,
        name: j['name'] as String? ?? '',
        passwordHash: j['passwordHash'] as String? ?? '',
        salt: j['salt'] as String? ?? '',
        avatarPath: j['avatarPath'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        website: j['website'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class Comment {
  const Comment({
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final String userId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        userId: j['userId'] as String,
        text: j['text'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.caption,
    required this.createdAt,
    this.location = '',
    this.likes = const [],
    this.comments = const [],
    this.savedBy = const [],
    this.isReel = false,
  });

  final String id;
  final String userId;
  final String imagePath;
  final String caption;
  final String location;
  final DateTime createdAt;
  final List<String> likes;
  final List<Comment> comments;
  final List<String> savedBy;
  final bool isReel;

  bool likedBy(String uid) => likes.contains(uid);
  bool savedFor(String uid) => savedBy.contains(uid);

  Post copyWith({
    List<String>? likes,
    List<Comment>? comments,
    List<String>? savedBy,
  }) {
    return Post(
      id: id,
      userId: userId,
      imagePath: imagePath,
      caption: caption,
      location: location,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      savedBy: savedBy ?? this.savedBy,
      isReel: isReel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'imagePath': imagePath,
        'caption': caption,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'comments': comments.map((c) => c.toJson()).toList(),
        'savedBy': savedBy,
        'isReel': isReel,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        userId: j['userId'] as String,
        imagePath: j['imagePath'] as String,
        caption: j['caption'] as String? ?? '',
        location: j['location'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        likes: ((j['likes'] as List?) ?? const []).cast<String>(),
        comments: ((j['comments'] as List?) ?? const [])
            .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        savedBy: ((j['savedBy'] as List?) ?? const []).cast<String>(),
        isReel: j['isReel'] as bool? ?? false,
      );
}

class ActivityItem {
  const ActivityItem({
    required this.actorId,
    required this.text,
    required this.createdAt,
    this.postId,
    this.targetId,
    this.isFollow = false,
  });

  final String actorId;
  final String text;
  final DateTime createdAt;
  final String? postId;
  final String? targetId;
  final bool isFollow;

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'postId': postId,
        'isFollow': isFollow,
        'targetId': targetId,
      };

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        actorId: j['actorId'] as String,
        text: j['text'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        postId: j['postId'] as String?,
        targetId: j['targetId'] as String?,
        isFollow: j['isFollow'] as bool? ?? false,
      );
}


class Story {
  const Story({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String imagePath;
  final DateTime createdAt;
  bool get isLive => DateTime.now().difference(createdAt) < const Duration(hours: 24);

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        userId: j['userId'] as String,
        imagePath: j['imagePath'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
