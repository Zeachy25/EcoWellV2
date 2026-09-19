import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../shared/ecowell_app_bar.dart';

class StressResultScreen extends StatelessWidget {
  final int preScore;
  final int postScore;
  final int reduction;
  final String spaceName;

  const StressResultScreen({
    super.key,
    required this.preScore,
    required this.postScore,
    required this.reduction,
    required this.spaceName,
  });

  String get _interpretation {
    if (reduction >= 5) return 'Significant Stress Relief';
    if (reduction >= 2) return 'Moderate Calming Effect';
    if (reduction > 0) return 'Mild Stress Reduction';
    if (reduction == 0) return 'Stable Wellness State';
    return 'Reflective State';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Stress Reduction Result',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryButtonGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.buttonGreen,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'OFFICIAL METRIC',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stress Reduction Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$reduction',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _interpretation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pre vs Post Score Breakdown Cards
            Row(
              children: [
                Expanded(
                  child: _buildScoreComparisonCard(
                    title: 'Pre-Visit PSS-4',
                    score: preScore,
                    subtitle: 'Baseline stress',
                    color: AppColors.streakOrange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildScoreComparisonCard(
                    title: 'Post-Visit PSS-4',
                    score: postScore,
                    subtitle: 'Current stress',
                    color: AppColors.mintGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nature Wellness AI Insight Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.psychology_alt_rounded, color: AppColors.mintGreen, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'EcoWell AI Wellness Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your session at $spaceName produced a +$reduction point reduction in perceived stress. Immersion in coastal and mangrove greenery stimulated your parasympathetic nervous system, lowering physiological arousal. Keep up this momentum!',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Share to Community Button
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/create-post');
                },
                icon: const Icon(Icons.share_rounded, color: AppColors.forestDark, size: 18),
                label: const Text(
                  'Share Reflection with Community',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forestDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forestDark, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Continue to Dashboard Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Wellness Dashboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreComparisonCard({
    required String title,
    required int score,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
