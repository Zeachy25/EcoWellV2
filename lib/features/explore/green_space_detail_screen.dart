import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive.dart';
import '../../models/place_review.dart';
import '../../providers/app_providers.dart';
import '../rating/quiet_score_dialog.dart';
import '../shared/crowd_level_bar.dart';
import '../shared/quiet_score_gauge.dart';

class GreenSpaceDetailScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const GreenSpaceDetailScreen({super.key, required this.spaceId});

  @override
  ConsumerState<GreenSpaceDetailScreen> createState() => _GreenSpaceDetailScreenState();
}

class _GreenSpaceDetailScreenState extends ConsumerState<GreenSpaceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(greenSpacesProvider);
    final space = spaces.firstWhere(
      (s) => s.id == widget.spaceId,
      orElse: () => spaces.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Hero Image Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: Responsive.size(context, 280),
            child: Stack(
              fit: StackFit.expand,
              children: [
                (space.imageUrl != null && space.imageUrl!.startsWith('http'))
                    ? Image.network(
                        space.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.forestMid,
                          child: const Center(
                            child: Icon(Icons.nature, color: Colors.white, size: 64),
                          ),
                        ),
                      )
                    : Image.asset(
                        space.imageUrl ?? 'assets/images/guang_guang_mangrove.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.forestMid,
                          child: const Center(
                            child: Icon(Icons.nature, color: Colors.white, size: 64),
                          ),
                        ),
                      ),
                // Gradient dark overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
                // Floating Back Button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.size(context, 12)),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        radius: Responsive.size(context, 20),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.forestDark, size: Responsive.size(context, 20)),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/explore');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable White Card Details Overlay
          Positioned.fill(
            top: Responsive.size(context, 230),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.size(context, 28))),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Responsive.size(context, 20),
                  Responsive.size(context, 20),
                  Responsive.size(context, 20),
                  Responsive.size(context, 40),
                ),
                children: [
                  // Space Name & Category
                  Text(
                    space.name,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 22),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: AppColors.forestDark,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 4)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: Responsive.size(context, 14), color: AppColors.mintGreen),
                      SizedBox(width: Responsive.size(context, 4)),
                      Expanded(
                        child: Text(
                          space.address,
                          style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 14)),

                  // "Highly Recommended" Tag
                  Row(
                    children: [
                      const Text('📌', style: TextStyle(fontSize: 16)),
                      SizedBox(width: Responsive.size(context, 6)),
                      Text(
                        'Highly Recommended',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 16)),

                  // Quiet Score Circular Gauge
                  Center(
                    child: QuietScoreGauge(
                      score: space.quietScore,
                      size: Responsive.size(context, 130),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 20)),

                  // Metric Progress Bars (Noise, Crowd, Calm)
                  CrowdLevelRow(title: 'Noise Level', level: space.noiseLevel),
                  CrowdLevelRow(title: 'Crowd Density', level: space.crowdDensity),
                  CrowdLevelRow(title: 'Calm Factor', level: space.calmFactor, isReversed: true),

                  SizedBox(height: Responsive.size(context, 20)),

                  // "Rate This Place" Outlined Button
                  Center(
                    child: SizedBox(
                      width: Responsive.size(context, 220),
                      height: Responsive.size(context, 44),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          QuietScoreDialog.show(context, space: space);
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.forestDark),
                        label: Text(
                          'Rate This Place',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDark,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.size(context, 22))),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.size(context, 18)),

                  // Primary Action: "Start Nature Visit"
                  Container(
                    width: double.infinity,
                    height: Responsive.size(context, 52),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryButtonGradient,
                      borderRadius: BorderRadius.circular(Responsive.size(context, 16)),
                      boxShadow: AppShadows.buttonGreen,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.push('/assessment?mode=pre&spaceId=${space.id}');
                        },
                        borderRadius: BorderRadius.circular(Responsive.size(context, 16)),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                              SizedBox(width: Responsive.size(context, 8)),
                              Text(
                                'Start Nature Visit',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 16),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.size(context, 28)),

                  // User Reviews Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User Reviews',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 20),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                          color: AppColors.forestDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.streakOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 14)),

                  // Review Cards matching mockup
                  ...space.reviews.map((review) => _buildReviewCard(review)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(PlaceReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.size(context, 14)),
      padding: EdgeInsets.all(Responsive.size(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.size(context, 16)),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Avatar
              CircleAvatar(
                radius: Responsive.size(context, 18),
                backgroundColor: AppColors.streakOrange.withValues(alpha: 0.15),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName.substring(0, 2).toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.w800,
                    color: AppColors.streakOrange,
                  ),
                ),
              ),
              SizedBox(width: Responsive.size(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 2)),
                    Text(
                      '2 days ago',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              // Circular Mini Rating Badge
              Container(
                padding: EdgeInsets.all(Responsive.size(context, 6)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mintGreen, width: 1.5),
                ),
                child: Text(
                  '${review.rating.toStringAsFixed(1)}\n/5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 9),
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestDark,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.size(context, 10)),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: Responsive.size(context, 8)),
          // Star ratings row
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating.floor() ? Icons.star : Icons.star_border,
                color: AppColors.goldStar,
                size: Responsive.size(context, 16),
              );
            }),
          ),
        ],
      ),
    );
  }
}