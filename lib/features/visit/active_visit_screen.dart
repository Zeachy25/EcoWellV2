import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive.dart';
import '../../providers/active_visit_provider.dart';
import '../shared/ecowell_app_bar.dart';

class ActiveVisitScreen extends ConsumerStatefulWidget {
  const ActiveVisitScreen({super.key});

  @override
  ConsumerState<ActiveVisitScreen> createState() => _ActiveVisitScreenState();
}

class _ActiveVisitScreenState extends ConsumerState<ActiveVisitScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeVisitProvider);
    final spaceName = active?.greenSpace.name ?? 'Guang-guang Mangrove Park';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Active Nature Visit',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Responsive.size(context, 20)),
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 20)),
              decoration: BoxDecoration(
                gradient: AppColors.primaryButtonGradient,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 24)),
                boxShadow: AppShadows.buttonGreen,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: Responsive.size(context, 10),
                        height: Responsive.size(context, 10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF48CAE4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VISIT IN PROGRESS',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 12),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 16)),
                  Text(
                    _formatDuration(_elapsed),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 48),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 8)),
                  Text(
                    spaceName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 12)),
                  // Geofence status chip
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.size(context, 12),
                      vertical: Responsive.size(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: const Color(0xFF48CAE4), size: Responsive.size(context, 14)),
                        SizedBox(width: Responsive.size(context, 4)),
                        Text(
                          'Within Nature Geofence (${active?.greenSpace.fenceLabel ?? '150 m radius'})',
                          style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            Text(
              'Guided Activities During Visit',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: AppColors.forestDark,
              ),
            ),
            SizedBox(height: Responsive.size(context, 4)),
            Text(
              'Try evidence-based mindfulness exercises while immersed in nature.',
              style: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.textSecondary),
            ),
            SizedBox(height: Responsive.size(context, 16)),

            // Activity 1: 4-7-8 Breathing
            _buildActivityCard(
              context,
              title: '4-7-8 Breathing',
              subtitle: '4s Inhale • 7s Hold • 8s Exhale',
              icon: Icons.air_rounded,
              color: AppColors.mintGreen,
              onTap: () => context.push('/activities/breathing'),
            ),

            // Activity 2: Box Breathing
            _buildActivityCard(
              context,
              title: 'Box Breathing',
              subtitle: '4s Inhale • 4s Hold • 4s Exhale • 4s Hold',
              icon: Icons.crop_square_rounded,
              color: AppColors.emerald,
              onTap: () => context.push('/activities/breathing'),
            ),

            // Activity 3: 5-4-3-2-1 Grounding
            _buildActivityCard(
              context,
              title: '5-4-3-2-1 Grounding',
              subtitle: 'Sensory nature exploration exercise',
              icon: Icons.touch_app_rounded,
              color: AppColors.streakOrange,
              onTap: () => context.push('/activities/grounding'),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            // End Visit & Post Assessment CTA
            Container(
              width: double.infinity,
              height: Responsive.size(context, 52),
              decoration: BoxDecoration(
                color: AppColors.forestDark,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
                boxShadow: AppShadows.card,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final spaceId = active?.greenSpace.id ?? 'gs-001';
                    context.push('/assessment?mode=post&spaceId=$spaceId');
                  },
                  borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
                  child: Center(
                    child: Text(
                      'Complete Visit & Post-Assessment',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.size(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.size(context, 16),
          vertical: Responsive.size(context, 8),
        ),
        leading: Container(
          padding: EdgeInsets.all(Responsive.size(context, 10)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: Responsive.size(context, 24)),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: Responsive.fontSize(context, 15), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: Responsive.size(context, 16), color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
