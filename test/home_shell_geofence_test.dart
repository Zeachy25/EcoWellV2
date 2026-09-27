import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecowell/data/local_store.dart';
import 'package:ecowell/features/home/home_shell.dart';
import 'package:ecowell/providers/active_visit_provider.dart';
import 'package:ecowell/providers/app_providers.dart';
import 'package:ecowell/providers/geofence_provider.dart';

/// Inside Dahican Beach (gs-004), and far outside every seeded fence.
const double _insideLat = 6.9091;
const double _insideLng = 126.2657;
const double _outsideLat = 6.9600;
const double _outsideLng = 126.3100;

/// Keeps the test off the real GPS stack; positions are injected instead.
class _TestGeofenceController extends GeofenceController {
  @override
  Future<void> startMonitoring() async {}
}

void main() {
  late _TestGeofenceController controller;
  late ProviderContainer container;
  late LocalStore _store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _store = LocalStore(await SharedPreferences.getInstance());
    controller = _TestGeofenceController();
    container = ProviderContainer(
      overrides: [
        geofenceProvider.overrideWith(() => controller),
        // HomeShell renders the draggable mascot, which reads its remembered
        // position from storage on first build.
        localStoreProvider.overrideWithValue(_store),
      ],
    );
  });

  tearDown(() => container.dispose());

  Widget app() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomeShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) =>
                      const Scaffold(body: Center(child: Text('home tab'))),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/assessment',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('assessment screen'))),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  void injectInside() => controller.debugInjectPosition(
        latitude: _insideLat,
        longitude: _insideLng,
      );

  void injectOutside() => controller.debugInjectPosition(
        latitude: _outsideLat,
        longitude: _outsideLng,
      );

  final welcome = find.text('Welcome to Dahican Beach');

  testWidgets('arriving shows the welcome dialog on the first inside fix', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(welcome, findsNothing);

    injectInside();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(welcome, findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Start Check'), findsOneWidget);
    expect(container.read(activeVisitProvider), isNull);
  });

  testWidgets('a single outside fix does not close the dialog', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    // One noisy fix is not enough, so the dialog must stay put.
    injectOutside();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(welcome, findsOneWidget);
  });

  testWidgets('a second outside fix closes the dialog and records nothing', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    injectOutside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    injectOutside();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(welcome, findsNothing);
    expect(container.read(activeVisitProvider), isNull);
  });

  testWidgets('flickering across the boundary never closes the dialog', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    injectOutside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    // Back inside: the exit tally resets, so the dialog must survive.
    injectInside();
    await tester.pumpAndSettle();

    expect(welcome, findsOneWidget);
  });

  testWidgets('re-entering after leaving prompts again', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();
    expect(welcome, findsOneWidget);

    injectOutside();
    await tester.pumpAndSettle();
    injectOutside();
    await tester.pumpAndSettle();
    expect(welcome, findsNothing);

    injectInside();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(welcome, findsOneWidget);
  });

  testWidgets('Start Check opens the assessment and begins a visit', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Check'));
    await tester.pumpAndSettle();

    expect(welcome, findsNothing);
    expect(find.text('assessment screen'), findsOneWidget);
    expect(container.read(activeVisitProvider), isNotNull);
  });

  testWidgets('Skip closes the dialog without beginning a visit', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(welcome, findsNothing);
    expect(find.text('assessment screen'), findsNothing);
    expect(container.read(activeVisitProvider), isNull);
  });

  testWidgets('leaving mid-check clears the abandoned visit', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    injectInside();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Check'));
    await tester.pumpAndSettle();
    final visit = container.read(activeVisitProvider);
    expect(visit, isNotNull);
    expect(visit!.preCompleted, isFalse);

    // Walking out without ever finishing the pre check drops the check-in.
    injectOutside();
    await tester.pumpAndSettle();
    injectOutside();
    await tester.pumpAndSettle();

    expect(container.read(activeVisitProvider), isNull);
  });
}
