import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../shared/ecowell_app_bar.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(greenSpacesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Mati Weather & Nature Forecast',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Responsive.size(context, 16)),
          children: [
            // Dark Forest Green Hero Weather Card
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 22)),
              decoration: BoxDecoration(
                color: AppColors.forestDark,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 24)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MATI CITY, DAVAO ORIENTAL',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 11),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                          SizedBox(height: Responsive.size(context, 4)),
                          Text(
                            'Optimal Nature Window',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 18),
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.size(context, 10),
                          vertical: Responsive.size(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestMid,
                          borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, color: AppColors.streakOrange, size: Responsive.size(context, 16)),
                            SizedBox(width: Responsive.size(context, 4)),
                            Text(
                              'UV: 4 (Moderate)',
                              style: TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 18)),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '28°C',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 52),
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: Responsive.size(context, 16)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mostly Sunny & Breezy',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 15),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: Responsive.size(context, 2)),
                          Text(
                            'Feels like 30°C • Humidity 74%',
                            style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textOnDarkMuted),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.size(context, 20)),
                  const Divider(color: Color(0xFF26533F)),
                  SizedBox(height: Responsive.size(context, 12)),

                  // Smart Recommendation Banner inside Weather Hero
                  Row(
                    children: [
                      Icon(Icons.spa_rounded, color: AppColors.mintGreen, size: Responsive.size(context, 20)),
                      SizedBox(width: Responsive.size(context, 8)),
                      Expanded(
                        child: Text(
                          'Best nature visit time today is between 3:30 PM – 5:45 PM before twilight sunset.',
                          style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: Colors.white, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.size(context, 22)),

            // Hourly Nature Suitability Forecast
            Text(
              'Hourly Nature Walk Forecast',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
                color: AppColors.forestDark,
              ),
            ),
            SizedBox(height: Responsive.size(context, 12)),

            SizedBox(
              height: Responsive.size(context, 110),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildHourlyCard(context, 'Now', '28°C', Icons.wb_sunny_rounded, 'Good', AppColors.mintGreen),
                  _buildHourlyCard(context, '2 PM', '29°C', Icons.wb_sunny_rounded, 'Warm', AppColors.streakOrange),
                  _buildHourlyCard(context, '3 PM', '28°C', Icons.cloud_queue_rounded, 'Optimal', AppColors.primaryGreen),
                  _buildHourlyCard(context, '4 PM', '27°C', Icons.cloud_queue_rounded, 'Perfect', AppColors.primaryGreen),
                  _buildHourlyCard(context, '5 PM', '26°C', Icons.wb_twilight_rounded, 'Sunset', AppColors.mintGreen),
                  _buildHourlyCard(context, '6 PM', '25°C', Icons.nightlight_round, 'Cool', AppColors.forestMid),
                ],
              ),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            // Recommended Spots for Current Weather
            Text(
              'Top Recommended Spots For Current Weather',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
                color: AppColors.forestDark,
              ),
            ),
            SizedBox(height: Responsive.size(context, 12)),

            ...spaces.take(3).map(
                  (space) => _buildWeatherRecommendedPlace(context, space),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyCard(BuildContext context, String time, String temp, IconData icon, String condition, Color badgeColor) {
    return Container(
      width: Responsive.size(context, 80),
      margin: EdgeInsets.only(right: Responsive.size(context, 10)),
      padding: EdgeInsets.symmetric(
        vertical: Responsive.size(context, 10),
        horizontal: Responsive.size(context, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          Icon(icon, color: AppColors.streakOrange, size: Responsive.size(context, 22)),
          Text(temp, style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w800, color: AppColors.forestDark)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.size(context, 6),
              vertical: Responsive.size(context, 2),
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Responsive.radius(context, 8)),
            ),
            child: Text(
              condition,
              style: TextStyle(fontSize: Responsive.fontSize(context, 9), fontWeight: FontWeight.w800, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRecommendedPlace(BuildContext context, GreenSpace space) {
    return GestureDetector(
      onTap: () => context.push('/green-space/${space.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.size(context, 12)),
        padding: EdgeInsets.all(Responsive.size(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 18)),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
              child: Container(
                width: Responsive.size(context, 70),
                height: Responsive.size(context, 70),
                color: AppColors.mintLight,
                child: Image.asset(
                  'assets/images/home.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.park, color: AppColors.forestMid),
                ),
              ),
            ),
            SizedBox(width: Responsive.size(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: Responsive.size(context, 2)),
                  Text(
                    '${space.category} • Shaded canopy & sea breeze',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
                  ),
                  SizedBox(height: Responsive.size(context, 6)),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.goldStar, size: Responsive.size(context, 14)),
                      SizedBox(width: Responsive.size(context, 2)),
                      Text(
                        '${space.quietScore.toStringAsFixed(1)} Quiet Score',
                        style: TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w700, color: AppColors.forestDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: Responsive.size(context, 14)),
          ],
        ),
      ),
    );
  }
}