class Story {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String? storyImage;
  final bool isUser;
  final bool hasUnseen;

  const Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.storyImage,
    this.isUser = false,
    this.hasUnseen = true,
  });
}
