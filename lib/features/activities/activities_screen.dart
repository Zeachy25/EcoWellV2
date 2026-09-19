import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../shared/ecowell_app_bar.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Guided Wellness Activities',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Responsive.size(context, 20)),
          children: [
            Text(
              'Mindfulness in Nature',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 22),
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
                color: AppColors.forestDark,
              ),
            ),
            SizedBox(height: Responsive.size(context, 6)),
            Text(
              'Select a guided activity to ground your senses and regulate your nervous system.',
              style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: AppColors.textSecondary, height: 1.35),
            ),
            SizedBox(height: Responsive.size(context, 20)),

            // Activity 1: 4-7-8 Breathing
            _buildActivityCard(
              context,
              title: '4-7-8 Breathing',
              tag: 'RELAXATION & SLEEP',
              description: 'Inhale for 4s, hold for 7s, and exhale for 8s to calm acute tension.',
              icon: Icons.air_rounded,
              color: AppColors.mintGreen,
              onTap: () => context.push('/activities/breathing'),
            ),

            // Activity 2: Box Breathing
            _buildActivityCard(
              context,
              title: 'Box Breathing',
              tag: 'FOCUS & CLARITY',
              description: 'Equal 4s intervals for inhale, hold, exhale, and hold used by mindfulness practitioners.',
              icon: Icons.crop_square_rounded,
              color: AppColors.emerald,
              onTap: () => context.push('/activities/box-breathing'),
            ),

            // Activity 3: 5-4-3-2-1 Grounding
            _buildActivityCard(
              context,
              title: '5-4-3-2-1 Grounding',
              tag: 'SENSORY IMMERSION',
              description: 'Anchor yourself in the present by noticing 5 things to see, 4 to touch, 3 to hear, 2 to smell, 1 to taste.',
              icon: Icons.touch_app_rounded,
              color: AppColors.streakOrange,
              onTap: () => context.push('/activities/grounding'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String tag,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.size(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
          child: Padding(
            padding: EdgeInsets.all(Responsive.size(context, 18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.size(context, 10),
                        vertical: Responsive.size(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(Responsive.size(context, 8)),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: Responsive.size(context, 22)),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.size(context, 12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.size(context, 6)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: Responsive.size(context, 14)),
                Row(
                  children: [
                    Text(
                      'Start Session',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 13),
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    SizedBox(width: Responsive.size(context, 4)),
                    Icon(Icons.arrow_forward_rounded, size: Responsive.size(context, 14), color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}