import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import '../../providers/ai_mascot_position_provider.dart';

/// Pixel-perfect vector AI mascot icon for EcoWell representing the
/// AI Wellness Companion (organic green ribbon 'S' wrap, white robot face,
/// antenna, and friendly eyes).
class EcoWellAiMascotIcon extends StatelessWidget {
  final double size;
  final bool withShadow;
  final Color? primaryGreen;
  final Color? secondaryGreen;
  final Color? faceColor;
  final Color? eyeColor;

  const EcoWellAiMascotIcon({
    super.key,
    this.size = 46,
    this.withShadow = false,
    this.primaryGreen,
    this.secondaryGreen,
    this.faceColor,
    this.eyeColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: EcoWellAiMascotPainter(
        withShadow: withShadow,
        primaryGreen: primaryGreen,
        secondaryGreen: secondaryGreen,
        faceColor: faceColor,
        eyeColor: eyeColor,
      ),
    );
  }
}

/// Painter that renders the custom EcoWell AI robot mascot with organic
/// leaf-ribbon swirls wrapping around a friendly robot head.
class EcoWellAiMascotPainter extends CustomPainter {
  final bool withShadow;
  final Color? primaryGreen;
  final Color? secondaryGreen;
  final Color? faceColor;
  final Color? eyeColor;

  EcoWellAiMascotPainter({
    this.withShadow = false,
    this.primaryGreen,
    this.secondaryGreen,
    this.faceColor,
    this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color topGreen = primaryGreen ?? const Color(0xFF40AA7D);
    final Color botGreen = secondaryGreen ?? const Color(0xFF287E5A);
    final Color face = faceColor ?? Colors.white;
    final Color eyes = eyeColor ?? const Color(0xFF14241C);

    // 1. Optional Drop Shadow behind the entire floating mascot
    if (withShadow) {
      final shadowPath = Path();
      shadowPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.52),
            width: w * 0.88,
            height: h * 0.82,
          ),
          Radius.circular(w * 0.32),
        ),
      );
      final shadowPaint = Paint()
        ..color = const Color(0xFF0F3223).withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.14);
      canvas.drawPath(shadowPath.shift(Offset(0, h * 0.08)), shadowPaint);
    }

    // 2. Draw Lower Green Ribbon (curves from right flank under chin to bottom-left)
    final botShader = LinearGradient(
      colors: [botGreen, const Color(0xFF1B5A40)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final botPaint = Paint()
      ..shader = botShader
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final botPath = Path();
    final double botBarH = h * 0.25;
    final double botBarY = h * 0.61;
    final double botCapRadius = botBarH / 2;

    // Bottom pill body extending left
    botPath.moveTo(w * 0.16 + botCapRadius, botBarY);
    botPath.lineTo(w * 0.80, botBarY);
    botPath.cubicTo(
      w * 0.94, botBarY,
      w * 0.94, botBarY + botBarH,
      w * 0.80, botBarY + botBarH,
    );
    botPath.lineTo(w * 0.16 + botCapRadius, botBarY + botBarH);
    botPath.arcToPoint(
      Offset(w * 0.16 + botCapRadius, botBarY),
      radius: Radius.circular(botCapRadius),
      clockwise: false,
    );
    botPath.close();

    // Right flank wing curving up towards top-right
    final rightWing = Path();
    rightWing.moveTo(w * 0.68, botBarY + botBarH * 0.1);
    rightWing.cubicTo(
      w * 0.95, botBarY * 0.88,
      w * 0.95, h * 0.44,
      w * 0.82, h * 0.38,
    );
    rightWing.lineTo(w * 0.66, h * 0.48);
    rightWing.cubicTo(
      w * 0.78, h * 0.52,
      w * 0.78, botBarY * 0.96,
      w * 0.68, botBarY + botBarH * 0.1,
    );
    rightWing.close();

    canvas.drawPath(botPath, botPaint);
    canvas.drawPath(rightWing, botPaint);

    // 3. Draw Robot White Head Face Capsule
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.49),
      width: w * 0.74,
      height: h * 0.43,
    );
    final headRRect = RRect.fromRectAndRadius(
      headRect,
      Radius.circular(h * 0.20),
    );

    final headPaint = Paint()
      ..color = face
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(headRRect, headPaint);

    // 4. Draw Upper Green Ribbon (curves from left flank over head to top-right)
    final topShader = LinearGradient(
      colors: [topGreen, botGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final topPaint = Paint()
      ..shader = topShader
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final topPath = Path();
    final double topBarH = h * 0.25;
    final double topBarY = h * 0.14;
    final double topCapRadius = topBarH / 2;

    // Top pill body extending right
    topPath.moveTo(w * 0.84 - topCapRadius, topBarY);
    topPath.lineTo(w * 0.20, topBarY);
    topPath.cubicTo(
      w * 0.06, topBarY,
      w * 0.06, topBarY + topBarH,
      w * 0.20, topBarY + topBarH,
    );
    topPath.lineTo(w * 0.84 - topCapRadius, topBarY + topBarH);
    topPath.arcToPoint(
      Offset(w * 0.84 - topCapRadius, topBarY),
      radius: Radius.circular(topCapRadius),
      clockwise: false,
    );
    topPath.close();

    // Left flank wing curving down towards bottom-left
    final leftWing = Path();
    leftWing.moveTo(w * 0.32, topBarY + topBarH * 0.9);
    leftWing.cubicTo(
      w * 0.05, topBarY + topBarH + h * 0.06,
      w * 0.05, h * 0.56,
      w * 0.18, h * 0.62,
    );
    leftWing.lineTo(w * 0.34, h * 0.52);
    leftWing.cubicTo(
      w * 0.22, h * 0.48,
      w * 0.22, topBarY + topBarH + h * 0.04,
      w * 0.32, topBarY + topBarH * 0.9,
    );
    leftWing.close();

    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(leftWing, topPaint);

    // 5. Draw Antenna on Top of Head
    final antennaStemPaint = Paint()
      ..color = face
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;

    final antennaPath = Path();
    antennaPath.moveTo(w * 0.50, h * 0.28);
    antennaPath.lineTo(w * 0.50, h * 0.16);
    canvas.drawPath(antennaPath, antennaStemPaint);

    final antennaBallPaint = Paint()
      ..color = face
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.50, h * 0.13), w * 0.065, antennaBallPaint);

    // 6. Draw Robot Eyes
    final eyePaint = Paint()
      ..color = eyes
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double eyeRadius = w * 0.078;
    final double eyeY = h * 0.49;
    final Offset leftEyeCenter = Offset(w * 0.38, eyeY);
    final Offset rightEyeCenter = Offset(w * 0.62, eyeY);

    canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

    // Specular eye reflections for a lively companion glance
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double glintRadius = eyeRadius * 0.32;

    canvas.drawCircle(
      Offset(leftEyeCenter.dx - eyeRadius * 0.28, leftEyeCenter.dy - eyeRadius * 0.28),
      glintRadius,
      glintPaint,
    );
    canvas.drawCircle(
      Offset(rightEyeCenter.dx - eyeRadius * 0.28, rightEyeCenter.dy - eyeRadius * 0.28),
      glintRadius,
      glintPaint,
    );
  }

  @override
  bool shouldRepaint(covariant EcoWellAiMascotPainter oldDelegate) =>
      oldDelegate.withShadow != withShadow ||
      oldDelegate.primaryGreen != primaryGreen ||
      oldDelegate.secondaryGreen != secondaryGreen ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.eyeColor != eyeColor;
}

/// Floating interactive button containing the EcoWell AI Mascot.
/// Placed above the bottom nav bar, it provides quick access to the AI Wellness
/// Companion with tactile touch feedback and subtle ambient breathing
/// animation. Pass the pan hooks to make it draggable.
class EcoWellAiButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool animate;

  /// Optional drag hooks. Tap and pan share one gesture arena, so leaving these
  /// null keeps the original tap-only behaviour.
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  /// True while the mascot is being dragged, which lifts it and holds it
  /// still instead of letting the breathing animation compete with the drag.
  final bool isDragging;

  const EcoWellAiButton({
    super.key,
    this.onPressed,
    this.size = 50,
    this.animate = true,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.isDragging = false,
  });

  @override
  State<EcoWellAiButton> createState() => _EcoWellAiButtonState();
}

class _EcoWellAiButtonState extends State<EcoWellAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.animate && !isTest) {
      _breatheController.repeat(reverse: true);
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      context.push('/ai-assistant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.size;

    return Semantics(
      label: 'Open AI Wellness Companion',
      button: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // While dragging the mascot is held steady and slightly larger, so
          // the ambient breathing does not compete with the movement.
          final scale = widget.isDragging
              ? 1.08
              : _isPressed
                  ? 0.90
                  : _scaleAnimation.value;
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _handleTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: EcoWellAiMascotIcon(
                    size: buttonSize,
                    withShadow: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Screen-wide draggable version of the AI mascot.
///
/// Lives in a full-screen overlay rather than inside the bottom nav: the nav's
/// Stack has a bounded height, and a child dragged outside its bounds stops
/// receiving touches, so it could not be moved freely from there.
///
/// The position is stored normalized (0..1 on both axes) against the mascot's
/// travel range, so it keeps the same relative spot on other screen sizes and
/// after rotation. Releasing snaps it to the nearer horizontal edge, and it is
/// never allowed to cover the bottom nav or the center action button.
class DraggableEcoWellAiMascot extends ConsumerStatefulWidget {
  /// Overrides the responsive default of 48 on the 390px design baseline.
  final double? size;

  /// Overrides the default navigation to the AI assistant.
  final VoidCallback? onTap;

  const DraggableEcoWellAiMascot({super.key, this.size, this.onTap});

  @override
  ConsumerState<DraggableEcoWellAiMascot> createState() =>
      _DraggableEcoWellAiMascotState();
}

class _DraggableEcoWellAiMascotState
    extends ConsumerState<DraggableEcoWellAiMascot>
    with SingleTickerProviderStateMixin {
  /// Clearance kept above the bottom nav so the mascot never covers the nav
  /// items or the center + button. The FAB's top edge sits about 94 design
  /// pixels above the nav's bottom, so match that with a little breathing room.
  static const double _bottomClearance = 98.0;

  /// Snap duration once the mascot is released.
  static const Duration _snapDuration = Duration(milliseconds: 220);

  /// Normalized live position, or null while it still sits at the default spot.
  Offset? _position;

  bool _dragging = false;

  /// Drives the edge snap after release. A plain implicit animation cannot be
  /// used, because it would also apply during the drag.
  late final AnimationController _snapController = AnimationController(
    vsync: this,
    duration: _snapDuration,
  )..addListener(() => setState(() {}));

  Offset _snapFrom = Offset.zero;
  Offset _snapTo = Offset.zero;

  @override
  void initState() {
    super.initState();
    _position = ref.read(aiMascotPositionProvider);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size ?? Responsive.size(context, 48);
    final double margin = Responsive.size(context, 6);
    final double topInset = Responsive.topPadding(context);
    final double bottomInset =
        Responsive.size(context, _bottomClearance) +
        Responsive.bottomPadding(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final Size screen = constraints.biggest;

        // Travel is the span the mascot may cover. The default parks it in the
        // top right just above the nav, matching where it used to sit.
        final double travelX = (screen.width - size - 2 * margin).clamp(
          0.0,
          double.infinity,
        );
        final double travelY =
            (screen.height - bottomInset - size - topInset).clamp(
              0.0,
              double.infinity,
            );

        Offset toPixels(Offset normalized) => Offset(
              margin + normalized.dx * travelX,
              topInset + normalized.dy * travelY,
            );

        Offset toNormalized(Offset pixel) => Offset(
              travelX == 0
                  ? 0
                  : ((pixel.dx - margin) / travelX).clamp(0.0, 1.0),
              travelY == 0
                  ? 0
                  : ((pixel.dy - topInset) / travelY).clamp(0.0, 1.0),
            );

        final bool snapping = _snapController.isAnimating;
        final Offset normalized = snapping
            ? Offset.lerp(
                _snapFrom,
                _snapTo,
                Curves.easeOutCubic.transform(_snapController.value),
              )!
            : (_position ?? Offset(1, travelY == 0 ? 0 : 1));
        final Offset pixel = toPixels(normalized);
        final bool lifted = _dragging || snapping;

        void handlePanStart(DragStartDetails details) {
          _snapController.stop();
          setState(() {
            _dragging = true;
            // Pin whatever is on screen, so a drag that interrupts a snap
            // starts from the visible position rather than the old target.
            _position = normalized;
          });
        }

        void handlePanUpdate(DragUpdateDetails details) {
          setState(() {
            _position = toNormalized(pixel + details.delta);
          });
        }

        void handlePanEnd(DragEndDetails details) {
          final Offset current = _position ?? normalized;
          final Offset target =
              Offset(current.dx < 0.5 ? 0 : 1, current.dy);
          setState(() {
            _dragging = false;
            _position = target;
            _snapFrom = current;
            _snapTo = target;
          });
          _snapController.forward(from: 0);
          unawaited(ref.read(aiMascotPositionProvider.notifier).save(target));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Deliberately a plain Positioned rather than AnimatedPositioned.
            // An implicit animation applies its new value a frame late, which
            // leaves the mascot's hit region trailing the finger, so a quick
            // flick would slide out from under the pointer and drop the drag.
            Positioned(
              left: pixel.dx,
              top: pixel.dy,
              width: size,
              height: size,
              child: EcoWellAiButton(
                size: size,
                isDragging: lifted,
                onPressed: widget.onTap,
                onPanStart: handlePanStart,
                onPanUpdate: handlePanUpdate,
                onPanEnd: handlePanEnd,
              ),
            ),
          ],
        );
      },
    );
  }
}
