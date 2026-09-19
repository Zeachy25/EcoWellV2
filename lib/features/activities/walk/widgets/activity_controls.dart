import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Interactive action controls for the live activity tracking session.
/// Provides large ergonomic Pause/Resume, Finish/Stop, and Recenter triggers
/// with accidental cancellation protection.
class ActivityControls extends StatelessWidget {
  const ActivityControls({
    super.key,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onDiscard,
    required this.onRecenter,
    this.isTrackingCamera = true,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onDiscard;
  final VoidCallback onRecenter;
  final bool isTrackingCamera;

  void _showStopSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Finish Activity?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.forestDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Save your walk to view detailed route analytics and eco-wellness stats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Finish & Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onFinish();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Finish & Save',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Resume button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onResume();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestDark,
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: const Text('Resume Activity'),
              ),
            ),
            const SizedBox(height: 12),
            // Discard button
            TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmDiscard(context);
              },
              child: const Text(
                'Discard Activity',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDiscard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Discard this activity?'),
        content: const Text(
          'Your recorded path and statistics for this session will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDiscard();
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Recenter Camera Button
            _SecondaryAction(
              icon: Icons.my_location,
              label: 'Recenter',
              isActive: isTrackingCamera,
              onTap: onRecenter,
            ),

            // Center Primary Action: Pause / Resume Button
            if (!isPaused)
              _LargeCircleButton(
                icon: Icons.pause,
                label: 'Pause',
                color: AppColors.streakOrange,
                onTap: onPause,
              )
            else
              _LargeCircleButton(
                icon: Icons.play_arrow,
                label: 'Resume',
                color: AppColors.primaryGreen,
                onTap: onResume,
              ),

            // Finish Button
            _SecondaryAction(
              icon: Icons.stop_rounded,
              label: 'Finish',
              isActive: false,
              color: isPaused ? const Color(0xFFE53935) : AppColors.textSecondary,
              onTap: () => _showStopSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeCircleButton extends StatelessWidget {
  const _LargeCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isActive ? AppColors.primaryGreen : AppColors.textSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.background,
          shape: const CircleBorder(),
          elevation: 1,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: effectiveColor, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: effectiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}