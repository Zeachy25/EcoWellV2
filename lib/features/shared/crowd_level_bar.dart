import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';

class CrowdLevelRow extends StatelessWidget {
  final String title;
  final CrowdLevel level;
  final bool isReversed; // For calm factor, high is good

  const CrowdLevelRow({
    super.key,
    required this.title,
    required this.level,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    double progress;
    String label;
    Color barColor;

    switch (level) {
      case CrowdLevel.low:
        progress = 0.25;
        label = 'Low';
        barColor = isReversed ? AppColors.scoreLow : AppColors.forestMid;
        break;
      case CrowdLevel.moderate:
        progress = 0.60;
        label = 'Moderate';
        barColor = AppColors.forestMid;
        break;
      case CrowdLevel.high:
        progress = 0.90;
        label = 'High';
        barColor = isReversed ? AppColors.forestMid : AppColors.scoreModerate;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.size(context, 6)),
      child: Row(
        children: [
          SizedBox(
            width: Responsive.size(context, 110),
            child: Text(
              title,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.radius(context, 6)),
              child: SizedBox(
                height: Responsive.size(context, 8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.mintLight,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.size(context, 16)),
          SizedBox(
            width: Responsive.size(context, 65),
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
