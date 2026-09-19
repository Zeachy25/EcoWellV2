import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class WeatherHeroCard extends StatelessWidget {
  final VoidCallback? onSeeMore;
  final bool showSeeMore;

  const WeatherHeroCard({
    super.key,
    this.onSeeMore,
    this.showSeeMore = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.size(context, 20)),
      decoration: BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestDark.withValues(alpha: 0.25),
            blurRadius: Responsive.size(context, 18),
            offset: Offset(0, Responsive.size(context, 8)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mati City, Davao Oriental',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          SizedBox(height: Responsive.size(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '28\u00B0C',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 52),
                  fontWeight: FontWeight.w300,
                  fontFamily: 'serif',
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              Icon(
                Icons.cloud_outlined,
                color: const Color(0xFFD4A373),
                size: Responsive.size(context, 64),
              ),
            ],
          ),
          Text(
            'Partly Cloudy',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.size(context, 16)),
          Row(
            children: [
              _buildMetricChip(context, Icons.water_drop_outlined, '72% Humidity'),
              SizedBox(width: Responsive.size(context, 8)),
              _buildMetricChip(context, Icons.air, '12 km/h'),
            ],
          ),
          SizedBox(height: Responsive.size(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricChip(context, Icons.wb_sunny_outlined, 'UV 6'),
              if (showSeeMore)
                GestureDetector(
                  onTap: onSeeMore,
                  child: Text(
                    'See More',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDarkMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.size(context, 12),
        vertical: Responsive.size(context, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: Responsive.size(context, 14)),
          SizedBox(width: Responsive.size(context, 6)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
