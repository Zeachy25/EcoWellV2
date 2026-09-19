import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seed_data.dart';
import '../models/app_user.dart';
import '../models/community_post.dart';
import '../models/story.dart';

class CommunityState {
  final List<Story> stories;
  final List<AppUser> suggestedUsers;
  final List<CommunityPost> posts;

  const CommunityState({
    required this.stories,
    required this.suggestedUsers,
    required this.posts,
  });

  CommunityState copyWith({
    List<Story>? stories,
    List<AppUser>? suggestedUsers,
    List<CommunityPost>? posts,
  }) {
    return CommunityState(
      stories: stories ?? this.stories,
      suggestedUsers: suggestedUsers ?? this.suggestedUsers,
      posts: posts ?? this.posts,
    );
  }
}

class CommunityNotifier extends Notifier<CommunityState> {
  @override
  CommunityState build() {
    return CommunityState(
      stories: seedStories,
      suggestedUsers: seedSuggestedUsers,
      posts: seedCommunityPosts,
    );
  }

  void toggleLike(String postId) {
    state = state.copyWith(
      posts: state.posts.map((post) {
        if (post.id == postId) {
          final isLiked = !post.isLiked;
          final countDelta = isLiked ? 1 : -1;
          return post.copyWith(
            isLiked: isLiked,
            likesCount: post.likesCount + countDelta,
          );
        }
        return post;
      }).toList(),
    );
  }

  void addComment(String postId) {
    state = state.copyWith(
      posts: state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentsCount: post.commentsCount + 1);
        }
        return post;
      }).toList(),
    );
  }

  void toggleFollowUser(String userId) {
    state = state.copyWith(
      suggestedUsers: state.suggestedUsers.map((user) {
        if (user.id == userId) {
          // If we add isFollowing to user or toggle
          return user;
        }
        return user;
      }).toList(),
    );
  }

  void removeSuggestedUser(String userId) {
    state = state.copyWith(
      suggestedUsers: state.suggestedUsers.where((u) => u.id != userId).toList(),
    );
  }

  void addUserPost(CommunityPost post) {
    state = state.copyWith(
      posts: [post, ...state.posts],
    );
  }

  void addNewPost({
    required String locationName,
    required String locationAddress,
    required String caption,
    required double rating,
    String? imageUrl,
  }) {
    final newPost = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current-user',
      userName: 'Arlene Rollorata',
      userAvatar: '',
      locationName: locationName,
      locationAddress: locationAddress,
      rating: rating,
      imageUrl: imageUrl ?? 'assets/images/Explore.png',
      caption: caption,
      likedByPreview: ['You'],
      likesCount: 1,
      commentsCount: 0,
      sharesCount: 0,
      isLiked: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      posts: [newPost, ...state.posts],
    );
  }
}

final communityProvider = NotifierProvider<CommunityNotifier, CommunityState>(
  CommunityNotifier.new,
);
