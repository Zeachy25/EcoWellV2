import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecowell/data/local_store.dart';
import 'package:ecowell/features/shared/ecowell_ai_mascot.dart';
import 'package:ecowell/providers/app_providers.dart';

/// The default flutter_test surface, which every expectation below assumes.
const double _surfaceWidth = 800;
const double _surfaceHeight = 600;

/// Mirrors Responsive.size on the fixed test surface, so the numbers in the
/// expectations match the widget's own math rather than being guessed.
double _scale(double designPx) => designPx * _surfaceWidth / 390;

final Finder _mascot = find.byType(EcoWellAiButton);

double get _mascotSize => _scale(48);
double get _edgeMargin => _scale(6);
double get _bottomClearance => _scale(98);
double get _travelX => _surfaceWidth - _mascotSize - 2 * _edgeMargin;
double get _travelY => _surfaceHeight - _bottomClearance - _mascotSize;

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderScope harness({VoidCallback? onTap, VoidCallback? onBackgroundTap}) {
    return ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                onTap: onBackgroundTap,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              Positioned.fill(
                child: DraggableEcoWellAiMascot(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drags the mascot through explicit move steps, pumping a real frame with a
  /// realistic interval between each one.
  ///
  /// TestGesture is used rather than tester.drag so the deltas are exact, and
  /// the gesture is primed with one small move first: Flutter's default
  /// DragStartBehavior.start discards the delta of the move that makes the pan
  /// recognizer accept the pointer, so without priming the whole list would be
  /// short by one step. The prime is far smaller than the mascot, so the
  /// pointer stays inside it for the rest of the drag.
  Future<void> dragMascot(WidgetTester tester, List<Offset> steps) async {
    final gesture = await tester.startGesture(tester.getCenter(_mascot));
    await gesture.moveBy(const Offset(-20, -10));
    await tester.pump(const Duration(milliseconds: 16));
    for (final step in steps) {
      await gesture.moveBy(step);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('dragging', () {
    testWidgets('a tap without movement still reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(harness(onTap: () => taps++));
      await tester.pumpAndSettle();

      await tester.tap(_mascot);
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('dragging repositions and does not count as a tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(harness(onTap: () => taps++));
      await tester.pumpAndSettle();

      // Two steps of -200 cross the snap midpoint, so the release settles on
      // the left edge instead of springing back to the right.
      await dragMascot(tester, const [Offset(-200, -60), Offset(-200, -60)]);

      expect(taps, 0, reason: 'the pan should win the gesture arena');
      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin, 1));
      expect(tester.getTopLeft(_mascot).dy, closeTo(_travelY - 120, 1));
    });

    testWidgets('every step of a fast flick is applied', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // Many small steps instead of one long jump, so a lost update shows up
      // as a shorter total displacement.
      await dragMascot(tester, List.filled(10, const Offset(-40, -20)));

      // A drag past the midpoint of the travel range snaps to the left edge.
      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin, 1));
      expect(
        tester.getTopLeft(_mascot).dy,
        closeTo(_travelY - 200, 1),
        reason: 'all ten steps of -20 vertical should have been applied',
      );
    });

    testWidgets('a step wider than the mascot does not drop the drag', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // Each step is wider than the mascot itself. If the rendered position
      // ever lagged a frame behind the pointer, the next move would land
      // outside the hit region and be silently discarded.
      expect(_mascotSize, lessThan(150));
      await dragMascot(tester, const [Offset(-150, -60), Offset(-150, -60)]);

      // -300 of travel is still nearest the right edge, so it springs back
      // there, but the vertical drop proves both steps were applied.
      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin + _travelX, 1));
      expect(tester.getTopLeft(_mascot).dy, closeTo(_travelY - 120, 1));
    });

    testWidgets('releasing snaps to the nearer horizontal edge', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // Starts at the right edge, so a small nudge left must snap back right.
      expect(
        tester.getTopLeft(_mascot).dx,
        closeTo(_edgeMargin + _travelX, 1),
      );

      await dragMascot(tester, const [Offset(-30, 0)]);
      expect(
        tester.getTopLeft(_mascot).dx,
        closeTo(_edgeMargin + _travelX, 1),
        reason: 'still nearest the right edge, so it springs back',
      );

      // A decisive move to the left must settle on the left edge.
      await dragMascot(tester, const [Offset(-300, 0), Offset(-300, 0)]);
      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin, 1));
    });
  });

  group('clamping', () {
    testWidgets('stays fully on screen when dragged past an edge', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await dragMascot(tester, const [Offset(-2000, 0)]);

      final topLeft = tester.getTopLeft(_mascot);
      expect(topLeft.dx, closeTo(_edgeMargin, 1));
      expect(topLeft.dx + _mascotSize, lessThanOrEqualTo(_surfaceWidth));
    });

    testWidgets('never drops over the bottom nav', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // The lowest reachable spot is the bottom of the travel range, which has
      // to leave the nav clearance below the mascot.
      await dragMascot(tester, const [Offset(0, 2000)]);

      final topLeft = tester.getTopLeft(_mascot);
      expect(topLeft.dy, closeTo(_travelY, 1));
      expect(
        topLeft.dy + _mascotSize,
        lessThanOrEqualTo(_surfaceHeight - _bottomClearance + 0.5),
      );
    });

    testWidgets('does not block taps on the screen beneath', (tester) async {
      var backgroundTaps = 0;
      await tester.pumpWidget(
        harness(onBackgroundTap: () => backgroundTaps++),
      );
      await tester.pumpAndSettle();

      // Well clear of the mascot, which defaults to the lower right.
      await tester.tapAt(const Offset(60, 60));
      await tester.pumpAndSettle();

      expect(backgroundTaps, 1);
    });
  });

  group('persistence', () {
    testWidgets('remembers the released position across restarts', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await dragMascot(tester, const [Offset(-300, 0), Offset(-300, 0)]);

      final stored = LocalStore(prefs).aiMascotPosition;
      expect(stored, isNotNull);
      expect(stored!.dx, 0, reason: 'snapped to the left edge');

      // A fresh pump with the same storage stands in for a relaunch.
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin, 1));
    });

    testWidgets('restores a previously saved position', (tester) async {
      await LocalStore(prefs).saveAiMascotPosition(Offset.zero);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_mascot).dx, closeTo(_edgeMargin, 1));
      expect(tester.getTopLeft(_mascot).dy, 0);
    });

    testWidgets('a stored position outside 0..1 is clamped', (tester) async {
      await LocalStore(prefs).saveAiMascotPosition(const Offset(4, -3));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(LocalStore(prefs).aiMascotPosition, const Offset(1, 0));
    });
  });

  group('navigation', () {
    testWidgets('tapping opens the AI assistant by default', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Stack(
                children: [Positioned.fill(child: DraggableEcoWellAiMascot())],
              ),
            ),
          ),
          GoRoute(
            path: '/ai-assistant',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('ai assistant'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_mascot);
      await tester.pumpAndSettle();

      expect(find.text('ai assistant'), findsOneWidget);
    });
  });
}
