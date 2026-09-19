import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../shared/ecowell_app_bar.dart';

class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _cycleSeconds = 16.0; // 4s each
  late AnimationController _controller;
  bool _paused = false;
  int _completedRounds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_cycleSeconds * 1000).round()),
    )..addListener(() => setState(() {}));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _completedRounds++);
        _controller.reset();
        if (!_paused) _controller.forward();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
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
      return (
        phase: 'Inhale',
        secondsLeft: (4.0 - elapsed).ceil(),
        scale: 0.75 + (0.35 * (elapsed / 4.0)),
      );
    } else if (elapsed < 8.0) {
      return (
        phase: 'Hold',
        secondsLeft: (8.0 - elapsed).ceil(),
        scale: 1.10,
      );
    } else if (elapsed < 12.0) {
      final exhaleElapsed = elapsed - 8.0;
      return (
        phase: 'Exhale',
        secondsLeft: (12.0 - elapsed).ceil(),
        scale: 1.10 - (0.35 * (exhaleElapsed / 4.0)),
      );
    } else {
      return (
        phase: 'Hold Empty',
        secondsLeft: (16.0 - elapsed).ceil(),
        scale: 0.75,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _getPhase(_controller.value);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Box Breathing (4-4-4-4)',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Round ${_completedRounds + 1} of 4',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              current.phase,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'serif', color: AppColors.forestDark),
            ),
            const SizedBox(height: 6),
            Text(
              '${current.secondsLeft}s',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.emerald),
            ),

            const Spacer(),

            // Animated Box / Square
            Center(
              child: Transform.scale(
                scale: current.scale,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.emerald, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.crop_square_rounded, color: AppColors.forestDark, size: 64),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Controls
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
