import 'package:flutter/material.dart';

import '../../../../models/walk_record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Interactive Kilometer Splits breakdown widget.
/// Visualizes pace comparison across each 1km lap with delta bars and highlight badges.
class SplitsChart extends StatelessWidget {
  const SplitsChart({super.key, required this.splits});

  final List<ActivitySplit> splits;

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Center(
          child: Text(
            'Keep going! Splits appear every 1.0 km completed.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Find fastest pace
    final fastestPace = splits
        .map((s) => s.avgPaceSecondsPerKm)
        .where((p) => p > 0)
        .fold<int>(999999, (a, b) => a < b ? a : b);

    final maxPace = splits
        .map((s) => s.avgPaceSecondsPerKm)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'KM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'PACE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'TIME',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'ELEV',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.cardBorder, height: 1),

        // Split Rows
        for (final split in splits)
          _SplitRow(
            split: split,
            isFastest: split.avgPaceSecondsPerKm == fastestPace &&
                splits.length > 1,
            maxPace: maxPace,
          ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.isFastest,
    required this.maxPace,
  });

  final ActivitySplit split;
  final bool isFastest;
  final int maxPace;

  @override
  Widget build(BuildContext context) {
    final paceMin = split.avgPaceSecondsPerKm ~/ 60;
    final paceSec =
        (split.avgPaceSecondsPerKm % 60).toString().padLeft(2, '0');
    final paceRatio = (split.avgPaceSecondsPerKm / (maxPace == 0 ? 1 : maxPace))
        .clamp(0.2, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isFastest ? AppColors.mintLight.withValues(alpha: 0.5) : null,
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // KM Label
          SizedBox(
            width: 48,
            child: Row(
              children: [
                Text(
                  '${split.splitNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFastest
                        ? AppColors.primaryGreen
                        : AppColors.textPrimary,
                  ),
                ),
                if (isFastest) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.bolt,
                    size: 14,
                    color: AppColors.streakOrange,
                  ),
                ],
              ],
            ),
          ),

          // Pace Bar + Pace Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$paceMin\'$paceSec" /km',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isFastest ? FontWeight.bold : FontWeight.w600,
                        color: isFastest
                            ? AppColors.forestDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (split.distanceMeters < 950)
                      Text(
                        ' (${(split.distanceMeters / 1000).toStringAsFixed(2)} km)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 4,
                    width: double.infinity,
                    color: AppColors.cardBorder,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: paceRatio,
                      child: Container(
                        color: isFastest
                            ? AppColors.primaryGreen
                            : AppColors.mintSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Duration
          SizedBox(
            width: 60,
            child: Text(
              _formatDuration(split.duration),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Elevation
          SizedBox(
            width: 60,
            child: Text(
              '+${split.elevationGainMeters.toStringAsFixed(0)}m',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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