import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class QuickActionBottomSheet extends StatelessWidget {
  const QuickActionBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QuickActionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Responsive.size(context, 20),
        Responsive.size(context, 16),
        Responsive.size(context, 20),
        Responsive.bottomPadding(context) + Responsive.size(context, 16),
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Responsive.size(context, 42),
            height: Responsive.size(context, 4),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: Responsive.size(context, 18)),
          Text(
            'Quick Wellness Actions',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              color: AppColors.forestDark,
            ),
          ),
          SizedBox(height: Responsive.size(context, 18)),

          _buildActionItem(
            context,
            icon: Icons.nature_people_rounded,
            title: 'Quick Run & Visits',
            subtitle: 'Track a mindful green space walk with GPS and Quiet Score',
            color: AppColors.primaryGreen,
            onTap: () {
              Navigator.pop(context);
              context.push('/walk');
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.add_photo_alternate_rounded,
            title: 'Share Community Post',
            subtitle: 'Post your nature photo, mood, and quiet rating',
            color: AppColors.streakOrange,
            onTap: () {
              Navigator.pop(context);
              context.push('/create-post');
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.spa_rounded,
            title: '4-7-8 Breathing Exercise',
            subtitle: 'Calm your parasympathetic nervous system in 2 mins',
            color: AppColors.emerald,
            onTap: () {
              Navigator.pop(context);
              context.push('/activities/breathing');
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.self_improvement_rounded,
            title: '5-4-3-2-1 Grounding',
            subtitle: 'Engage your senses to ground your mind in nature',
            color: AppColors.jade,
            onTap: () {
              Navigator.pop(context);
              context.push('/activities/grounding');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.size(context, 10)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
          child: Container(
            padding: EdgeInsets.all(Responsive.size(context, 12)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.size(context, 10)),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: Responsive.size(context, 20)),
                ),
                SizedBox(width: Responsive.size(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Responsive.size(context, 2)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 11),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: Responsive.size(context, 14), color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
