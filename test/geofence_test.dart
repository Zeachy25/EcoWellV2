import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecowell/core/utils/geo.dart';
import 'package:ecowell/data/seed_data.dart';
import 'package:ecowell/features/explore/explore_map_screen.dart';
import 'package:ecowell/features/home/home_shell.dart';
import 'package:ecowell/features/shared/geofence_status_chip.dart';
import 'package:ecowell/models/geo_fence.dart';
import 'package:ecowell/models/green_space.dart';
import 'package:ecowell/providers/active_visit_provider.dart';
import 'package:ecowell/providers/geofence_provider.dart';

void main() {
  group('sortSpacesByDistance', () {
    GreenSpace fakeSpace(String id, {double? distanceKm}) => GreenSpace(
          id: id,
          name: id,
          description: 'desc',
          category: 'Beach',
          address: 'addr',
          latitude: 0,
          longitude: 0,
          amenities: const [],
          distanceKm: distanceKm,
        );

    double? metersOf(GreenSpace s) => s.distanceKm == null ? null : s.distanceKm! * 1000;

    test('sorts nearest first', () {
      final spaces = [
        fakeSpace('far', distanceKm: 9.8),
        fakeSpace('near', distanceKm: 0.2),
        fakeSpace('mid', distanceKm: 2.1),
      ];
      final sorted = sortSpacesByDistance(spaces, metersOf);
      expect(sorted.map((e) => e.id).toList(), ['near', 'mid', 'far']);
    });

    test('null distances sort last and keep relative seed order', () {
      final spaces = [
        fakeSpace('a'),
        fakeSpace('b', distanceKm: 0.5),
        fakeSpace('c'),
        fakeSpace('d'),
      ];
      final sorted = sortSpacesByDistance(spaces, metersOf);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a', 'c', 'd']);
    });

    test('does not mutate the input list', () {
      final spaces = [
        fakeSpace('far', distanceKm: 9.8),
        fakeSpace('near', distanceKm: 0.2),
      ];
      sortSpacesByDistance(spaces, metersOf);
      expect(spaces.map((e) => e.id).toList(), ['far', 'near']);
    });
  });

  group('formatGeoDistance', () {
    test('under 1 km shows meters', () {
      expect(formatGeoDistance(9), '9 m');
      expect(formatGeoDistance(0), '0 m');
      expect(formatGeoDistance(999.4), '999 m');
    });

    test('at or over 1 km shows one-decimal km', () {
      expect(formatGeoDistance(1000), '1.0 km');
      expect(formatGeoDistance(1200), '1.2 km');
      expect(formatGeoDistance(9203.7), '9.2 km');
    });
  });

  group('CircleFence.contains', () {
    const fence = CircleFence(
      latitude: 6.9091,
      longitude: 126.2657,
      radiusMeters: 200,
    );

    test('center is inside', () {
      expect(fence.contains(6.9091, 126.2657), isTrue);
    });

    test('far city-center point is outside', () {
      expect(fence.contains(6.95, 126.2157), isFalse);
    });
  });

  group('PolygonFence.contains', () {
    final square = PolygonFence(const [
      GeoCoord(0, 0),
      GeoCoord(0, 2),
      GeoCoord(2, 2),
      GeoCoord(2, 0),
    ]);

    test('point inside the quadrilateral is inside', () {
      expect(square.contains(1, 1), isTrue);
      expect(square.contains(0.1, 0.1), isTrue);
    });

    test('point outside the quadrilateral is outside', () {
      expect(square.contains(3, 3), isFalse);
      expect(square.contains(-1, 1), isFalse);
    });

    test('Dahican Beach resolves to a polygon and contains its anchor', () {
      final dahican = matiGreenSpaces.firstWhere((s) => s.id == 'gs-004');
      expect(dahican.fence, isA<PolygonFence>());
      expect(dahican.fence.contains(6.9091, 126.2657), isTrue);
    });

    test('seed places without vertices resolve to circles', () {
      final guang = matiGreenSpaces.firstWhere((s) => s.id == 'gs-001');
      expect(guang.fence, isA<CircleFence>());
      expect(guang.fence.contains(guang.latitude, guang.longitude), isTrue);
    });
  });

  group('resolveGeofenceAction', () {
    final space = matiGreenSpaces.first;

    ActiveVisit visit({bool preCompleted = true}) => ActiveVisit(
          id: 'v-1',
          greenSpace: space,
          startTime: DateTime.now(),
          preAnswers: preCompleted ? const [1, 2, 3, 4] : null,
          preScore: preCompleted ? 8 : null,
        );

    GeofenceState outside() => const GeofenceState(monitoring: true);

    GeofenceState inside() => GeofenceState(
          monitoring: true,
          insideSpace: space,
          position: null,
        );

    test('entering with no active visit prompts the pre-assessment', () {
      expect(resolveGeofenceAction(outside(), inside(), null),
          GeofenceAction.promptArrival);
    });

    test('entering with an active visit does not prompt again', () {
      expect(resolveGeofenceAction(outside(), inside(), visit()),
          GeofenceAction.none);
    });

    test('exiting with a completed pre-assessment prompts post-check', () {
      expect(resolveGeofenceAction(inside(), outside(), visit()),
          GeofenceAction.promptDeparture);
    });

    test('exiting mid-check clears the abandoned visit', () {
      // The user tapped Start Check but never finished the pre-assessment, so
      // the stale check-in is dropped and returning to the place prompts again.
      expect(
          resolveGeofenceAction(inside(), outside(), visit(preCompleted: false)),
          GeofenceAction.clearAbandonedVisit);
    });

    test('exiting with no active visit does not prompt', () {
      expect(resolveGeofenceAction(inside(), outside(), null),
          GeofenceAction.none);
    });

    test('no state change resolves to none', () {
      expect(resolveGeofenceAction(inside(), inside(), null),
          GeofenceAction.none);
      expect(resolveGeofenceAction(outside(), outside(), visit()),
          GeofenceAction.none);
    });
  });

  group('GeofenceStatusChip', () {
    testWidgets('default state shows the monitor is inactive',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GeofenceStatusChip()),
          ),
        ),
      );
      expect(find.text('Geofence monitor inactive'), findsOneWidget);
    });

    testWidgets('tapping the chip lists every geofenced place',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GeofenceStatusChip()),
          ),
        ),
      );

      await tester.tap(find.byType(GeofenceStatusChip));
      await tester.pumpAndSettle();

      expect(find.text('Geofenced Places'), findsOneWidget);
      expect(find.text('Move outside all fences'), findsOneWidget);
      for (final space in matiGreenSpaces) {
        expect(find.text(space.name), findsWidgets);
      }
    });

    testWidgets('injected position inside Dahican shows Inside state',
        (tester) async {
      final controller = GeofenceController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geofenceProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GeofenceStatusChip()),
          ),
        ),
      );

      controller.debugInjectPosition(latitude: 6.9091, longitude: 126.2657);
      await tester.pump();

      expect(find.text('Inside Dahican Beach'), findsOneWidget);
    });
  });
}