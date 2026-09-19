import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/community_post.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTapLocation;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTapLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.size(context, 20)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 18)),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: Responsive.size(context, 14),
            offset: Offset(0, Responsive.size(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Location + Rating
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.size(context, 16),
              vertical: Responsive.size(context, 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.mintGreen,
                  size: Responsive.size(context, 20),
                ),
                SizedBox(width: Responsive.size(context, 8)),
                Expanded(
                  child: InkWell(
                    onTap: onTapLocation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.locationName,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: Responsive.size(context, 2)),
                        Text(
                          post.locationAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 11),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Responsive.size(context, 8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rating:',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.textTertiary),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.goldStar, size: Responsive.size(context, 16)),
                        SizedBox(width: Responsive.size(context, 2)),
                        Text(
                          post.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nature Photo
          ClipRRect(
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: post.imageUrl.startsWith('http')
                  ? Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.mintLight,
                        child: Center(
                          child: Icon(Icons.nature, color: AppColors.forestMid, size: Responsive.size(context, 48)),
                        ),
                      ),
                    )
                  : Image.asset(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.mintLight,
                        child: Center(
                          child: Icon(Icons.nature, color: AppColors.forestMid, size: Responsive.size(context, 48)),
                        ),
                      ),
                    ),
            ),
          ),

          // Caption (if any)
          if (post.caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.size(context, 16),
                Responsive.size(context, 10),
                Responsive.size(context, 16),
                Responsive.size(context, 4),
              ),
              child: Text(
                post.caption,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),

          // Liked By row + Comments counter
          Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.size(context, 16),
              Responsive.size(context, 8),
              Responsive.size(context, 16),
              Responsive.size(context, 4),
            ),
            child: Row(
              children: [
                // Overlapping avatar circles
                SizedBox(
                  width: Responsive.size(context, 44),
                  height: Responsive.size(context, 20),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: Responsive.size(context, 9),
                          backgroundColor: AppColors.mintGreen,
                          child: Text('J', style: TextStyle(fontSize: Responsive.fontSize(context, 8), color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        left: Responsive.size(context, 10),
                        child: CircleAvatar(
                          radius: Responsive.size(context, 9),
                          backgroundColor: AppColors.streakOrange,
                          child: Text('M', style: TextStyle(fontSize: Responsive.fontSize(context, 8), color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        left: Responsive.size(context, 20),
                        child: CircleAvatar(
                          radius: Responsive.size(context, 9),
                          backgroundColor: AppColors.forestMid,
                          child: Text('A', style: TextStyle(fontSize: Responsive.fontSize(context, 8), color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.size(context, 6)),
                Expanded(
                  child: Text(
                    'Liked by ${post.likedByPreview.join(", ")}...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  '${(post.commentsCount / 1000).toStringAsFixed(1)}k comments',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          Divider(height: Responsive.size(context, 12), color: AppColors.cardBorder),

          // Reaction Bar: Heart, Comment, Share
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.size(context, 16),
              vertical: Responsive.size(context, 8),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : AppColors.textPrimary,
                    size: Responsive.size(context, 22),
                  ),
                  onPressed: onLike,
                ),
                SizedBox(width: Responsive.size(context, 6)),
                Text(
                  '${(post.likesCount / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                SizedBox(width: Responsive.size(context, 24)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.textPrimary,
                    size: Responsive.size(context, 20),
                  ),
                  onPressed: onComment,
                ),
                const Spacer(),
                Text(
                  '${(post.sharesCount / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                SizedBox(width: Responsive.size(context, 6)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.share_outlined,
                    color: AppColors.textPrimary,
                    size: Responsive.size(context, 20),
                  ),
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
