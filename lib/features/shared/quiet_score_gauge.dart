import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuietScoreGauge extends StatelessWidget {
  final double score;
  final double maxScore;
  final double size;
  final bool showLabel;

  const QuietScoreGauge({
    super.key,
    required this.score,
    this.maxScore = 5.0,
    this.size = 140,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (score / maxScore).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow / circle background
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestMid.withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Circular progress stroke
              SizedBox(
                width: size * 0.9,
                height: size * 0.9,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.mintSoft.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestMid),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Score text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: AppColors.forestDark,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ ${maxScore.toInt()}',
                    style: TextStyle(
                      fontSize: size * 0.11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 10),
          const Text(
            'QUIET SCORE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.mintGreen,
            ),
          ),
        ],
      ],
    );
  }
}
