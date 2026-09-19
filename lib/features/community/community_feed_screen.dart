import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../providers/community_provider.dart';
import '../shared/ecowell_app_bar.dart';
import '../shared/post_card.dart';
import '../shared/story_avatar.dart';
import '../shared/who_to_follow_card.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityProvider);
    final spaces = ref.watch(greenSpacesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        showBack: false,
        showUserAvatar: true,
        showNotifications: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            Responsive.size(context, 8),
            Responsive.horizontalPadding(context),
            Responsive.bottomNavClearance(context),
          ),
          children: [
            // Stories / MyDay Row matching Explore.png
            SizedBox(
              height: Responsive.size(context, 90),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: community.stories.length,
                itemBuilder: (context, index) {
                  final story = community.stories[index];
                  return StoryAvatar(
                    story: story,
                    onTap: () {
                      if (story.isUser) {
                        context.push('/create-post');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing ${story.userName}\'s nature story...')),
                        );
                      }
                    },
                  );
                },
              ),
            ),

            SizedBox(height: Responsive.size(context, 14)),

            // "Suggested" Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.streakOrange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 12)),

            // Horizontal Suggested Users Carousel
            SizedBox(
              height: Responsive.size(context, 195),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: community.suggestedUsers.length,
                separatorBuilder: (context, index) => SizedBox(width: Responsive.size(context, 12)),
                itemBuilder: (context, index) {
                  final user = community.suggestedUsers[index];
                  return WhoToFollowCard(
                    user: user,
                    onFollow: () => ref.read(communityProvider.notifier).toggleFollowUser(user.id),
                    onRemove: () => ref.read(communityProvider.notifier).removeSuggestedUser(user.id),
                  );
                },
              ),
            ),

            SizedBox(height: Responsive.size(context, 20)),

            // Community Posts Feed
            ...community.posts.map(
              (post) => PostCard(
                post: post,
                onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
                onComment: () => ref.read(communityProvider.notifier).addComment(post.id),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${post.locationName} post...')),
                  );
                },
                onTapLocation: () {
                  final space = spaces.firstWhere(
                    (s) => s.name.toLowerCase().contains(post.locationName.toLowerCase().split(' ').first),
                    orElse: () => spaces.first,
                  );
                  context.push('/green-space/${space.id}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
