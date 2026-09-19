class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String locationName;
  final String locationAddress;
  final double rating;
  final String imageUrl;
  final String caption;
  final List<String> likedByPreview;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isFollowing;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.locationName,
    required this.locationAddress,
    required this.rating,
    required this.imageUrl,
    required this.caption,
    required this.likedByPreview,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    this.isLiked = false,
    this.isFollowing = false,
    required this.createdAt,
  });

  CommunityPost copyWith({
    bool? isLiked,
    int? likesCount,
    bool? isFollowing,
    int? commentsCount,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      locationName: locationName,
      locationAddress: locationAddress,
      rating: rating,
      imageUrl: imageUrl,
      caption: caption,
      likedByPreview: likedByPreview,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt,
    );
  }
}
