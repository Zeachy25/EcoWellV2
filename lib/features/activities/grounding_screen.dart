import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../shared/ecowell_app_bar.dart';

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  static const _steps = [
    (
      '5',
      'Things you can SEE',
      'Look around the green space. Notice colors of leaves, light through branches, textures of stone or water.',
      Icons.visibility_rounded,
      AppColors.mintGreen,
    ),
    (
      '4',
      'Things you can TOUCH',
      'Feel the texture of tree bark, breeze against your skin, solid ground beneath your feet, or cool grass.',
      Icons.touch_app_rounded,
      AppColors.emerald,
    ),
    (
      '3',
      'Things you can HEAR',
      'Listen closely. Birds chirping, rustling leaves, ocean waves, or distant gentle winds.',
      Icons.hearing_rounded,
      AppColors.primaryGreen,
    ),
    (
      '2',
      'Things you can SMELL',
      'Inhale the natural environment. Damp earth, sea salt in the air, pine needles, or blossoming flora.',
      Icons.air_rounded,
      AppColors.streakOrange,
    ),
    (
      '1',
      'Thing you can TASTE',
      'Notice the freshness in your mouth, a sip of water, or simply the cool fresh air.',
      Icons.restaurant_rounded,
      AppColors.forestMid,
    ),
  ];

  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];
    final progress = (_step + 1) / _steps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: '5-4-3-2-1 Sensory Grounding',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.mintLight,
                  valueColor: AlwaysStoppedAnimation<Color>(current.$5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Step ${_step + 1} of ${_steps.length}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),

              const Spacer(),

              // Interactive Step Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: current.$5.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          current.$1,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'serif',
                            color: current.$5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      current.$2,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'serif',
                        color: AppColors.forestDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      current.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Next / Finish Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      _showCompleteDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: current.$5,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _step < _steps.length - 1 ? 'Next Sense' : 'Complete Exercise',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (_step > 0) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text(
                    'Previous Sense',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 48),
        title: const Text(
          'Mindfully Grounded!',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, color: AppColors.forestDark),
        ),
        content: const Text(
          'You have completed the 5-4-3-2-1 Sensory Grounding exercise. Notice how your mind has settled into the present moment.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Finish Session'),
            ),
          ),
        ],
      ),
    );
  }
}