import 'package:flutter/material.dart';

import '../../../../models/walk_record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Floating Heads-Up Display (HUD) for live activity recording.
/// Displays key stats (distance, time, live pace, calories, elevation),
/// GPS accuracy indicator, and split toast banners.
class LiveHudOverlay extends StatelessWidget {
  const LiveHudOverlay({
    super.key,
    required this.activityType,
    required this.distanceKm,
    required this.movingDuration,
    required this.currentPaceSecondsPerKm,
    required this.avgPaceSecondsPerKm,
    required this.calories,
    required this.elevationGainMeters,
    required this.isPaused,
    this.latestSplit,
    this.destinationName,
  });

  final WalkActivityType activityType;
  final double distanceKm;
  final Duration movingDuration;
  final int currentPaceSecondsPerKm;
  final int avgPaceSecondsPerKm;
  final int calories;
  final double elevationGainMeters;
  final bool isPaused;
  final ActivitySplit? latestSplit;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top status pill (Activity type + GPS status + Destination)
        _TopStatusBar(
          activityType: activityType,
          destinationName: destinationName,
          isPaused: isPaused,
        ),
        const SizedBox(height: 10),

        // Split alert toast if recently triggered
        if (latestSplit != null) ...[
          _SplitAlertToast(split: latestSplit!),
          const SizedBox(height: 8),
        ],

        // Main Live Metrics Card
        _MetricsCard(
          distanceKm: distanceKm,
          movingDuration: movingDuration,
          currentPaceSecondsPerKm: currentPaceSecondsPerKm,
          avgPaceSecondsPerKm: avgPaceSecondsPerKm,
          calories: calories,
          elevationGainMeters: elevationGainMeters,
          isPaused: isPaused,
        ),
      ],
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar({
    required this.activityType,
    this.destinationName,
    required this.isPaused,
  });

  final WalkActivityType activityType;
  final String? destinationName;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPaused
            ? AppColors.streakOrange
            : AppColors.forestDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaused
                ? Icons.pause_circle_filled
                : activityType.icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            isPaused
                ? 'PAUSED'
                : (destinationName != null
                    ? '${activityType.label}  ·  $destinationName'
                    : activityType.label),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaused ? Colors.white : AppColors.mintSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitAlertToast extends StatelessWidget {
  const _SplitAlertToast({required this.split});

  final ActivitySplit split;

  @override
  Widget build(BuildContext context) {
    final paceMin = split.avgPaceSecondsPerKm ~/ 60;
    final paceSec =
        (split.avgPaceSecondsPerKm % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.streakOrange,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Km ${split.splitNumber} split: $paceMin\'$paceSec" /km',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.distanceKm,
    required this.movingDuration,
    required this.currentPaceSecondsPerKm,
    required this.avgPaceSecondsPerKm,
    required this.calories,
    required this.elevationGainMeters,
    required this.isPaused,
  });

  final double distanceKm;
  final Duration movingDuration;
  final int currentPaceSecondsPerKm;
  final int avgPaceSecondsPerKm;
  final int calories;
  final double elevationGainMeters;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Hero primary numbers: Distance & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PrimaryStat(
                  label: 'DISTANCE',
                  value: distanceKm.toStringAsFixed(2),
                  unit: 'km',
                  color: AppColors.forestDark,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.cardBorder,
                ),
                _PrimaryStat(
                  label: isPaused ? 'TIME (PAUSED)' : 'MOVING TIME',
                  value: _formatDuration(movingDuration),
                  unit: '',
                  color: isPaused ? AppColors.streakOrange : AppColors.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),

            // Secondary metrics row: Pace, Calories, Elevation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SecondaryStat(
                  label: 'Pace',
                  value: _formatPace(
                    currentPaceSecondsPerKm > 0
                        ? currentPaceSecondsPerKm
                        : avgPaceSecondsPerKm,
                  ),
                  icon: Icons.speed,
                ),
                _SecondaryStat(
                  label: 'Calories',
                  value: '$calories kcal',
                  icon: Icons.local_fire_department,
                ),
                _SecondaryStat(
                  label: 'Elev Gain',
                  value: '${elevationGainMeters.toStringAsFixed(0)} m',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryStat extends StatelessWidget {
  const _PrimaryStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _SecondaryStat extends StatelessWidget {
  const _SecondaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryGreen),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

String _formatPace(int paceSecPerKm) {
  if (paceSecPerKm <= 0) return '—';
  final m = paceSecPerKm ~/ 60;
  final s = (paceSecPerKm % 60).toString().padLeft(2, '0');
  return "$m'$s\" /km";
}