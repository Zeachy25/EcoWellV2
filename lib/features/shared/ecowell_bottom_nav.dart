import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import 'action_bottom_sheet.dart';

class EcoWellBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const EcoWellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navBarHeight = Responsive.size(context, 56);
    final topSpace = Responsive.size(context, 58);
    final totalHeight = navBarHeight + topSpace + Responsive.bottomPadding(context);
    final fabSize = Responsive.size(context, 56);
    final notchGap = Responsive.size(context, 58);
    // How far the FAB dips below the bar's top edge into the notch cradle.
    final fabDip = Responsive.size(context, 18);

    return Container(
      margin: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        0,
        Responsive.horizontalPadding(context),
        Responsive.size(context, 12),
      ),
      height: totalHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background Notched Gradient Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navBarHeight,
            child: CustomPaint(
              painter: _NotchedNavBarPainter(),
              child: SizedBox(
                height: navBarHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 14)),
                  child: Row(
                    children: [
                      // Left Group: Home & Nature (Explore)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(
                              context: context,
                              index: 0,
                              icon: Icons.home_rounded,
                              isLeftGradient: true,
                            ),
                            _buildNavItem(
                              context: context,
                              index: 1,
                              icon: Icons.eco_rounded,
                              isLeftGradient: true,
                            ),
                          ],
                        ),
                      ),

                      // Space for center notch & FAB
                      SizedBox(width: notchGap),

                      // Right Group: Map & Stats Dashboard
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(
                              context: context,
                              index: 2,
                              icon: Icons.map_rounded,
                              isLeftGradient: false,
                            ),
                            _buildNavItem(
                              context: context,
                              index: 3,
                              icon: Icons.bar_chart_rounded,
                              isLeftGradient: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Central Floating Action Button (+) elevated prominently
          Positioned(
            bottom: navBarHeight - fabDip,
            child: GestureDetector(
              onTap: () => QuickActionBottomSheet.show(context),
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF40AA7D), Color(0xFF287E5A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F3223).withValues(alpha: 0.45),
                      blurRadius: Responsive.size(context, 14),
                      offset: Offset(0, Responsive.size(context, 6)),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: Responsive.size(context, 34),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required bool isLeftGradient,
  }) {
    final isSelected = currentIndex == index;
    final itemSize = Responsive.size(context, 38);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isLeftGradient
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.22))
                  : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected && isLeftGradient
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: Responsive.size(context, 6),
                        offset: Offset(0, Responsive.size(context, 2)),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: Responsive.size(context, isSelected ? 21 : 23),
                color: isLeftGradient
                    ? (isSelected
                        ? const Color(0xFF23764E)
                        : const Color(0xFF153325).withValues(alpha: 0.8))
                    : (isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that creates the curved pill shape with a center notch
/// and a highlighted cradle scoop contour.
class _NotchedNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double pillRadius = size.height / 2;
    final double cx = size.width / 2;
    const double notchRadius = 31.0;
    const double sRadius = 12.0;
    const double notchDepth = 22.0;

    final double p1x = cx - notchRadius - sRadius;
    final double p2x = cx - notchRadius;
    final double p4x = cx + notchRadius;
    final double p5x = cx + notchRadius + sRadius;

    // Create Main Pill Path with Notch Cutout
    final Path path = Path();
    path.moveTo(pillRadius, 0);

    // Flat top left line to shoulder
    path.lineTo(p1x, 0);

    // Left shoulder curve down into notch
    path.cubicTo(
      p1x + sRadius * 0.5, 0,
      p2x - 2, notchDepth * 0.15,
      p2x, notchDepth * 0.5,
    );
    // Left notch curve to bottom of scoop
    path.cubicTo(
      p2x + 3, notchDepth * 0.95,
      cx - notchRadius * 0.45, notchDepth,
      cx, notchDepth,
    );
    // Right notch curve up from bottom of scoop
    path.cubicTo(
      cx + notchRadius * 0.45, notchDepth,
      p4x - 3, notchDepth * 0.95,
      p4x, notchDepth * 0.5,
    );
    // Right shoulder curve up to flat top
    path.cubicTo(
      p4x + 2, notchDepth * 0.15,
      p5x - sRadius * 0.5, 0,
      p5x, 0,
    );

    // Flat top right line to corner
    path.lineTo(size.width - pillRadius, 0);

    // Right rounded capsule edge
    path.arcToPoint(
      Offset(size.width, pillRadius),
      radius: Radius.circular(pillRadius),
    );
    path.arcToPoint(
      Offset(size.width - pillRadius, size.height),
      radius: Radius.circular(pillRadius),
    );

    // Bottom straight line
    path.lineTo(pillRadius, size.height);

    // Left rounded capsule edge
    path.arcToPoint(
      Offset(0, pillRadius),
      radius: Radius.circular(pillRadius),
    );
    path.arcToPoint(
      Offset(pillRadius, 0),
      radius: Radius.circular(pillRadius),
    );
    path.close();

    // 1. Draw Deep Ambient Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF0C241B).withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);

    // 2. Draw Horizontal Gradient Fill (Mint -> Medium Green -> Deep Pine)
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF75C19F), // Fresh mint on the left
          Color(0xFF388F70), // Transition emerald/green in the middle
          Color(0xFF1B4F3E), // Deep dark pine/teal on the right
        ],
        stops: [0.0, 0.50, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);

    // 3. Draw Scoop Highlight Contour (The elegant carved cradle rim)
    final Path rimPath = Path();
    rimPath.moveTo(p1x, 0);
    rimPath.cubicTo(
      p1x + sRadius * 0.5, 0,
      p2x - 2, notchDepth * 0.15,
      p2x, notchDepth * 0.5,
    );
    rimPath.cubicTo(
      p2x + 3, notchDepth * 0.95,
      cx - notchRadius * 0.45, notchDepth,
      cx, notchDepth,
    );
    rimPath.cubicTo(
      cx + notchRadius * 0.45, notchDepth,
      p4x - 3, notchDepth * 0.95,
      p4x, notchDepth * 0.5,
    );
    rimPath.cubicTo(
      p4x + 2, notchDepth * 0.15,
      p5x - sRadius * 0.5, 0,
      p5x, 0,
    );

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(p1x, 0, p5x - p1x, notchDepth));

    canvas.drawPath(rimPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
