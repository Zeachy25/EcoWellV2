import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/app_user.dart';

class WhoToFollowCard extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onFollow;
  final VoidCallback? onRemove;

  const WhoToFollowCard({
    super.key,
    required this.user,
    this.onFollow,
    this.onRemove,
  });

  @override
  State<WhoToFollowCard> createState() => _WhoToFollowCardState();
}

class _WhoToFollowCardState extends State<WhoToFollowCard> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Responsive.size(context, 155),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.size(context, 12),
        vertical: Responsive.size(context, 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: Responsive.size(context, 10),
            offset: Offset(0, Responsive.size(context, 4)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: Responsive.size(context, 28),
            backgroundColor: AppColors.mintSoft,
            child: Text(
              widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 22),
                fontWeight: FontWeight.bold,
                color: AppColors.forestDark,
              ),
            ),
          ),
          SizedBox(height: Responsive.size(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.user.isVerified) ...[
                SizedBox(width: Responsive.size(context, 4)),
                Icon(
                  Icons.check_circle,
                  color: AppColors.streakOrange,
                  size: Responsive.size(context, 14),
                ),
              ],
            ],
          ),
          SizedBox(height: Responsive.size(context, 2)),
          Text(
            '${widget.user.followersCount} Followers',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 11),
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: Responsive.size(context, 12)),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: Responsive.size(context, 28),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _following = !_following);
                      widget.onFollow?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _following ? AppColors.forestMid : AppColors.streakOrange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _following ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 11),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.size(context, 6)),
              Expanded(
                child: SizedBox(
                  height: Responsive.size(context, 28),
                  child: OutlinedButton(
                    onPressed: widget.onRemove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                      ),
                    ),
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 11),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
