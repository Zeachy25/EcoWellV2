import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../shared/ecowell_app_bar.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _cycleSeconds = 19.0; // 4s inhale + 7s hold + 8s exhale
  late AnimationController _controller;
  Timer? _ticker;
  bool _paused = false;
  int _completedRounds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_cycleSeconds * 1000).round()),
    )..addListener(() {
        setState(() {});
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _completedRounds++);
        _controller.reset();
        if (!_paused) _controller.forward();
      }
    });

    _controller.forward();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && !_paused) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _controller.stop();
      } else {
        _controller.forward();
      }
    });
  }

  void _reset() {
    _controller.reset();
    setState(() {
      _completedRounds = 0;
      _paused = false;
    });
    _controller.forward();
  }

  ({String phase, int secondsLeft, double scale}) _getPhase(double value) {
    final elapsed = value * _cycleSeconds;
    if (elapsed < 4.0) {
      final progress = elapsed / 4.0;
      return (
        phase: 'Inhale through nose',
        secondsLeft: (4.0 - elapsed).ceil(),
        scale: 0.7 + (0.35 * progress),
      );
    } else if (elapsed < 11.0) {
      final holdElapsed = elapsed - 4.0;
      return (
        phase: 'Hold your breath',
        secondsLeft: (7.0 - holdElapsed).ceil(),
        scale: 1.05,
      );
    } else {
      final exhaleElapsed = elapsed - 11.0;
      final progress = exhaleElapsed / 8.0;
      return (
        phase: 'Exhale slowly through mouth',
        secondsLeft: (8.0 - exhaleElapsed).ceil(),
        scale: 1.05 - (0.35 * progress),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _getPhase(_controller.value);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: '4-7-8 Relaxing Breath',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Round ${_completedRounds + 1} of 4',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              current.phase,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
                color: AppColors.forestDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${current.secondsLeft}s',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.mintGreen,
              ),
            ),

            const Spacer(),

            // Animated Breathing Orb
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer soft glowing aura
                  Transform.scale(
                    scale: current.scale * 1.3,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mintSoft.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  // Middle ring
                  Transform.scale(
                    scale: current.scale * 1.15,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mintLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  // Core pulsing circle
                  Transform.scale(
                    scale: current.scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryButtonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forestMid.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.spa_rounded, color: Colors.white, size: 54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Controls (Pause, Reset)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
                    label: Text(_paused ? 'Resume' : 'Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}