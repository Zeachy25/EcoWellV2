import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/visit.dart';
import '../../providers/app_providers.dart';
import '../../providers/streak_provider.dart';
import '../../providers/visits_provider.dart';
import 'widgets/confetti_overlay.dart';
import 'widgets/streak_flame_painter.dart';

/// Full-screen celebration dialog displaying the radiant Daily Streak flame,
/// festive confetti particles, and the 7-day weekly progress tracker.
class DailyStreakDialog extends ConsumerWidget {
  final int? streakOverride;

  const DailyStreakDialog({
    super.key,
    this.streakOverride,
  });

  /// Displays the Daily Streak celebration dialog.
  static Future<void> show(BuildContext context, {int? streak}) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Daily Streak',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return DailyStreakDialog(streakOverride: streak);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Shows the Daily Streak celebration at most once per day, and only when the
  /// day was actually earned: a real visit recorded today.
  ///
  /// Simply opening the app is not enough. A user with no visits never sees the
  /// dialog, and one who visits a green space and completes the check-in gets it
  /// exactly once, on the first screen load after the visit lands.
  static Future<void> checkAndShowDaily(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final List<Visit> visits;
    try {
      visits = await ref.read(visitsProvider.future);
    } catch (_) {
      return;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final earnedToday = visits.any(
      (v) => DateUtils.dateOnly(v.startTime) == today,
    );
    if (!earnedToday) return;

    final localStore = ref.read(localStoreProvider);
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (localStore.lastStreakCelebrationDate != todayKey) {
      await localStore.setLastStreakCelebrationDate(todayKey);
      if (context.mounted) {
        await show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentStreak = streakOverride ?? ref.watch(currentStreakProvider);
    final int displayStreak = currentStreak < 0 ? 0 : currentStreak;
    final weeklyDays = ref.watch(weeklyStreakProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted background blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),

          // Festive Confetti & Streamers Overlay
          const ConfettiOverlay(),

          // Main Content Column
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: Responsive.size(context, 12),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Bar with Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.85),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.forestDark,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.size(context, 8)),

                      // Center Radiant Streak Flame Graphic
                      StreakFlameWidget(
                        streakCount: displayStreak,
                        size: Responsive.size(context, 180).clamp(140.0, 195.0),
                      ),

                      SizedBox(height: Responsive.size(context, 20)),

                      // Bottom 7-Day Weekly Tracker Card
                      _buildWeeklyCard(context, weeklyDays, displayStreak),

                      SizedBox(height: Responsive.size(context, 20)),

                      // Action Button: "Keep Going!"
                      SizedBox(
                        width: double.infinity,
                        height: Responsive.size(context, 50).clamp(44.0, 54.0),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.streakOrange,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.streakOrange.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.radius(context, 16),
                              ),
                            ),
                          ),
                          child: Text(
                            _getActionLabel(displayStreak),
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 15),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(
    BuildContext context,
    List<WeeklyStreakDay> weeklyDays,
    int streak,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.size(context, 12).clamp(10.0, 16.0),
        vertical: Responsive.size(context, 16).clamp(12.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.radius(context, 24).clamp(16.0, 24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3223).withValues(alpha: 0.14),
            blurRadius: Responsive.size(context, 20).clamp(10.0, 20.0),
            offset: Offset(0, Responsive.size(context, 8).clamp(4.0, 8.0)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 7-Day Row: Mon, Tue, Wed, Thu, Fri, Sat, Sun
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeklyDays.map((day) {
              return Expanded(
                child: _buildDayItem(context, day),
              );
            }).toList(),
          ),

          SizedBox(height: Responsive.size(context, 16).clamp(10.0, 16.0)),

          // Horizontal Divider Line
          Container(
            width: double.infinity,
            height: 1.0,
            color: const Color(0xFFE2EBE5),
          ),

          SizedBox(height: Responsive.size(context, 14).clamp(8.0, 14.0)),

          // Motivational Message: "Nice work!"
          Text(
            _getMotivationalTitle(streak),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: AppColors.streakOrange,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: Responsive.size(context, 4)),
          Text(
            _getStreakHint(streak),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B5045),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(BuildContext context, WeeklyStreakDay day) {
    final double circleSize = Responsive.size(context, 32).clamp(24.0, 36.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular Status Indicator
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: day.isCompleted
                ? const Color(0xFF2E9E6B)
                : (day.isToday
                    ? const Color(0xFFE8F5EE)
                    : const Color(0xFFF5FAF7)),
            border: Border.all(
              color: day.isCompleted
                  ? const Color(0xFF237E55)
                  : (day.isToday
                      ? const Color(0xFF38B289)
                      : const Color(0xFF90D5B7)),
              width: day.isToday ? 2.0 : 1.4,
            ),
            boxShadow: day.isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E9E6B).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: day.isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: Responsive.size(context, 18).clamp(14.0, 20.0),
                  )
                : (day.isToday
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF38B289),
                        ),
                      )
                    : null),
          ),
        ),
        SizedBox(height: Responsive.size(context, 6).clamp(3.0, 6.0)),
        // Day Label
        Text(
          day.label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 12),
            fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
            color: day.isToday
                ? AppColors.textPrimary
                : const Color(0xFF55695C),
          ),
        ),
      ],
    );
  }

  String _getMotivationalTitle(int streak) {
    if (streak <= 0) return 'Start your streak';
    if (streak <= 1) return 'Nice work!';
    if (streak <= 3) return 'Great momentum!';
    if (streak <= 6) return 'You are on fire!';
    return 'Streak Champion!';
  }

  String _getStreakHint(int streak) {
    if (streak <= 0) return 'Check in at a green space to earn Day 1';
    return 'Let\'s make it Day ${streak + 1} tomorrow';
  }

  String _getActionLabel(int streak) {
    return streak <= 0 ? 'Find a Green Space' : 'Awesome, Keep Going!';
  }
}

/// Standalone Screen wrapper for route navigation `/streak`
class DailyStreakScreen extends StatelessWidget {
  const DailyStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DailyStreakDialog();
  }
}
