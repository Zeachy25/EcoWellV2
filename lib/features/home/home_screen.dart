import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/community_provider.dart';
import '../../providers/streak_provider.dart';
import '../shared/ecowell_app_bar.dart';
import '../shared/post_card.dart';
import '../shared/weather_hero_card.dart';
import '../shared/who_to_follow_card.dart';
import '../streak/daily_streak_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        DailyStreakDialog.checkAndShowDaily(context, ref);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(currentStreakProvider);
    final community = ref.watch(communityProvider);
    final spaces = ref.watch(greenSpacesProvider);
    final featuredSpace = spaces.isNotEmpty ? spaces.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        showBack: false,
        showUserAvatar: true,
        showNotifications: true,
        showSettings: true,
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
            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: Responsive.size(context, 48),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 14)),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textTertiary, size: Responsive.size(context, 20)),
                        SizedBox(width: Responsive.size(context, 8)),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search green spaces in Mati...',
                              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: Responsive.fontSize(context, 13)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Responsive.size(context, 10)),
                // Filter Button
                GestureDetector(
                  onTap: () => context.push('/explore'),
                  child: Container(
                    width: Responsive.size(context, 48),
                    height: Responsive.size(context, 48),
                    decoration: BoxDecoration(
                      color: AppColors.streakOrange,
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                    ),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: Responsive.size(context, 22)),
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.size(context, 18)),

            // Hero Banner: "FIND YOUR NEXT GREEN ESCAPE"
            _buildHeroEscapeBanner(context, featuredSpace),

            SizedBox(height: Responsive.size(context, 16)),

            // Streak Card (Orange Amber)
            _buildStreakBanner(context, streak),

            SizedBox(height: Responsive.size(context, 16)),

            // Weather Card (Dark Forest Green)
            WeatherHeroCard(
              onSeeMore: () => context.push('/weather'),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            // Who to Follow Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Who to Follow',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/community'),
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
            SizedBox(
              height: Responsive.size(context, 195),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: community.suggestedUsers.length,
                separatorBuilder: (context, index) => SizedBox(width: Responsive.size(context, 12)),
                itemBuilder: (context, index) {
                  final suggested = community.suggestedUsers[index];
                  return WhoToFollowCard(
                    user: suggested,
                    onFollow: () => ref.read(communityProvider.notifier).toggleFollowUser(suggested.id),
                    onRemove: () => ref.read(communityProvider.notifier).removeSuggestedUser(suggested.id),
                  );
                },
              ),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            // Wellness Score by Location Section Header
            Text(
              'Wellness Score by Location',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: Responsive.size(context, 4)),
            Text(
              'Recommended for you - explore nearby places to help you relax, stay active, and recharge.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            SizedBox(height: Responsive.size(context, 14)),

            // Community & Location Posts Feed
            ...community.posts.map(
              (post) => PostCard(
                post: post,
                onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
                onComment: () => ref.read(communityProvider.notifier).addComment(post.id),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${post.locationName} link...')),
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

  Widget _buildHeroEscapeBanner(BuildContext context, GreenSpace? space) {
    return Container(
      width: double.infinity,
      height: Responsive.size(context, 155),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA7E3CE), Color(0xFFC3EEDF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
        child: Stack(
          children: [
            // Layered photo montage preview
            Positioned(
              right: Responsive.size(context, 10),
              top: Responsive.size(context, 10),
              bottom: Responsive.size(context, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                child: Image.asset(
                  'assets/images/nature_escape_banner.png',
                  width: Responsive.size(context, 150),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: Responsive.size(context, 150),
                    color: AppColors.mintGreen,
                    child: Icon(Icons.nature, color: Colors.white, size: Responsive.size(context, 36)),
                  ),
                ),
              ),
            ),
            // Text Banner
            Positioned(
              left: Responsive.size(context, 18),
              top: Responsive.size(context, 20),
              bottom: Responsive.size(context, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIND YOUR',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: AppColors.forestDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 15),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: AppColors.forestDark,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'GREEN ESCAPE',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 15),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: AppColors.forestDark,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (space != null) {
                        context.push('/green-space/${space.id}');
                      } else {
                        context.push('/explore');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.size(context, 14),
                        vertical: Responsive.size(context, 8),
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Explore Now',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context, int streak) {
    return GestureDetector(
      onTap: () => DailyStreakDialog.show(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.size(context, 16),
          vertical: Responsive.size(context, 14),
        ),
        decoration: BoxDecoration(
          gradient: AppColors.streakGradient,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
          boxShadow: AppShadows.buttonOrange,
        ),
        child: Row(
          children: [
            // Fire icon
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 8)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_fire_department, color: Colors.white, size: Responsive.size(context, 28)),
            ),
            SizedBox(width: Responsive.size(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR STREAK • $streak ${streak == 1 ? 'DAY' : 'DAYS'}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 2)),
                  Text(
                    'Start your streak by visiting nature',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => DailyStreakDialog.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.streakCoral,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.size(context, 14),
                  vertical: Responsive.size(context, 10),
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
                ),
                elevation: 0,
              ),
              child: Text(
                'View',
                style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
