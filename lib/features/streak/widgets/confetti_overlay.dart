import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders celebratory confetti particles and spiraling streamers for the
/// Daily Streak celebration background.
class ConfettiOverlay extends StatefulWidget {
  final Widget? child;

  const ConfettiOverlay({super.key, this.child});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ConfettiPainter(progress: _controller.value),
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  // Curated festive colors matching the mockup
  static const List<Color> _palette = [
    Color(0xFF00C9FF), // Cyan
    Color(0xFFFF2A85), // Magenta / Hot Pink
    Color(0xFFFFC300), // Gold / Amber
    Color(0xFF2EC4B6), // Teal Emerald
    Color(0xFFFF5722), // Deep Coral Orange
    Color(0xFF8338EC), // Vivid Violet
    Color(0xFF70E000), // Fresh Lime
    Color(0xFFFF85A1), // Soft Rose
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw spiraling ribbon streamers
    _drawRibbon(
      canvas,
      startX: w * 0.28,
      startY: h * 0.18,
      color: const Color(0xFFC77DFF).withValues(alpha: 0.65),
      turns: 3,
      radius: w * 0.09,
      height: h * 0.45,
    );

    _drawRibbon(
      canvas,
      startX: w * 0.78,
      startY: h * 0.25,
      color: const Color(0xFF90E0EF).withValues(alpha: 0.65),
      turns: 2.5,
      radius: w * 0.08,
      height: h * 0.38,
    );

    _drawRibbon(
      canvas,
      startX: w * 0.16,
      startY: h * 0.50,
      color: const Color(0xFFFFB4A2).withValues(alpha: 0.6),
      turns: 2,
      radius: w * 0.07,
      height: h * 0.30,
    );

    // Deterministic pseudo-random confetti particles based on index
    const int particleCount = 42;
    for (int i = 0; i < particleCount; i++) {
      final color = _palette[i % _palette.length];
      
      // Calculate animated floating position
      final baseSeedX = (math.sin(i * 997.0) * 0.5 + 0.5);
      final baseSeedY = (math.cos(i * 613.0) * 0.5 + 0.5);
      
      final currentY = (baseSeedY + progress * 0.15 + (i * 0.02)) % 1.0;
      final px = baseSeedX * w + math.sin(progress * 2 * math.pi + i) * 6;
      final py = currentY * h;

      final double particleSize = (i % 3 == 0) ? 9.0 : ((i % 2 == 0) ? 6.5 : 5.0);
      final double rotation = (i * 45.0 + progress * 180.0) * math.pi / 180.0;

      final paint = Paint()
        ..color = color.withValues(alpha: (i % 5 == 0) ? 0.9 : 0.75)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      // Depth of field blur on some particles
      if (i % 7 == 0) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      }

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);

      if (i % 3 == 0) {
        // Rectangle confetti
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: particleSize * 1.8, height: particleSize * 0.7),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else if (i % 3 == 1) {
        // Diamond confetti
        final path = Path();
        path.moveTo(0, -particleSize * 0.8);
        path.lineTo(particleSize * 0.6, 0);
        path.lineTo(0, particleSize * 0.8);
        path.lineTo(-particleSize * 0.6, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Circular / Oval confetti
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: particleSize, height: particleSize * 0.8),
          paint,
        );
      }

      canvas.restore();
    }
  }

  void _drawRibbon(
    Canvas canvas, {
    required double startX,
    required double startY,
    required Color color,
    required double turns,
    required double radius,
    required double height,
  }) {
    final ribbonPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(startX, startY);

    final int segments = (turns * 12).toInt();
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = t * turns * 2 * math.pi;
      final x = startX + math.cos(angle) * radius;
      final y = startY + t * height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
