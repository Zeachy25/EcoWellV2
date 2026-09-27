import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ecowell/features/shared/route_line.dart';

const List<LatLng> _points = [LatLng(7.2, 125.4), LatLng(7.21, 125.41)];

void main() {
  group('RouteLine', () {
    test('uses the same color and width as the recorded activity trail', () {
      // The recorded trail is drawn as a #4285F4 line at width 5.
      expect(RouteLine.plannedColor, const Color(0xFF4285F4));
      expect(RouteLine.plannedWidth, 5);
    });

    test('renders a real route solid', () {
      final line = RouteLine.polyline(id: 'r', points: _points);

      expect(line, isNotNull);
      expect(line!.color, RouteLine.plannedColor);
      expect(line.width, RouteLine.plannedWidth);
      expect(line.patterns, isEmpty);
      expect(line.points, _points);
    });

    test('keeps the trail color and width on the dashed fallback', () {
      final line = RouteLine.polyline(id: 'r', points: null, fallback: _points);

      expect(line, isNotNull);
      expect(line!.width, RouteLine.plannedWidth);
      expect(line.patterns, RouteLine.fallbackPattern);
      // Same blue family, just faded so the dashed path reads as provisional.
      expect(line.color, RouteLine.fallbackColor);
      expect(
        line.color.computeLuminance(),
        greaterThan(0.0),
        reason: 'fallback must stay visible',
      );
    });

    test('falls back when the route has fewer than two points', () {
      expect(
        RouteLine.polyline(id: 'r', points: const [LatLng(1, 2)]).toString(),
        'null',
      );

      final line = RouteLine.polyline(
        id: 'r',
        points: const [LatLng(1, 2)],
        fallback: _points,
      );
      expect(line!.patterns, RouteLine.fallbackPattern);
    });

    test('returns null when neither route nor fallback is drawable', () {
      expect(RouteLine.polyline(id: 'r', points: null), isNull);
      expect(
        RouteLine.polyline(
          id: 'r',
          points: null,
          fallback: const [LatLng(1, 2)],
        ),
        isNull,
      );
    });

    test('keeps the supplied polyline id and zIndex', () {
      final line = RouteLine.polyline(
        id: 'destination-route',
        points: _points,
        zIndex: 5,
      );

      expect(line!.polylineId, const PolylineId('destination-route'));
      expect(line.zIndex, 5);
    });

    test('isRealRoute requires at least two points', () {
      expect(RouteLine.isRealRoute(_points), isTrue);
      expect(RouteLine.isRealRoute(const [LatLng(1, 2)]), isFalse);
      expect(RouteLine.isRealRoute(null), isFalse);
    });
  });
}
