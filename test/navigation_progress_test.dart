import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ecowell/data/services/navigation_location_filter.dart';
import 'package:ecowell/features/navigation/route_progress.dart';

Position _position({
  required double latitude,
  required double longitude,
  required DateTime timestamp,
  double accuracy = 5,
  double speed = 1,
  double heading = 90,
  double headingAccuracy = 10,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: headingAccuracy,
    speed: speed,
    speedAccuracy: 1,
  );
}

void main() {
  group('NavigationLocationFilter', () {
    test('rejects inaccurate fixes', () {
      final filter = NavigationLocationFilter();
      final result = filter.add(
        _position(
          latitude: 6,
          longitude: 126,
          timestamp: DateTime.now(),
          accuracy: 100,
        ),
      );

      expect(result, isNull);
    });

    test('rejects an unrealistic jump', () {
      final filter = NavigationLocationFilter();
      final start = DateTime.now();
      expect(
        filter.add(_position(latitude: 6, longitude: 126, timestamp: start)),
        isNotNull,
      );

      expect(
        filter.add(
          _position(
            latitude: 6.01,
            longitude: 126,
            timestamp: start.add(const Duration(seconds: 1)),
          ),
        ),
        isNull,
      );
    });

    test('retains a reliable heading when a stationary fix has no heading', () {
      final filter = NavigationLocationFilter();
      final start = DateTime.now();
      final first = filter.add(
        _position(
          latitude: 6,
          longitude: 126,
          timestamp: start,
          speed: 2,
          heading: 90,
        ),
      );
      final second = filter.add(
        _position(
          latitude: 6.00001,
          longitude: 126,
          timestamp: start.add(const Duration(seconds: 2)),
          speed: 0,
          heading: 0,
          headingAccuracy: 0,
        ),
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second!.headingDegrees, closeTo(90, 1));
    });

    test('rejects an abrupt heading flip until the next fix confirms it', () {
      final filter = NavigationLocationFilter(
        config: const NavigationLocationFilterConfig(
          headingSmoothingFactor: 1,
        ),
      );
      final start = DateTime.now();
      final first = filter.add(
        _position(
          latitude: 6,
          longitude: 126,
          timestamp: start,
          speed: 2,
          heading: 10,
        ),
      );
      final flipped = filter.add(
        _position(
          latitude: 6.0001,
          longitude: 126,
          timestamp: start.add(const Duration(seconds: 1)),
          speed: 2,
          heading: 220,
        ),
      );
      final confirmed = filter.add(
        _position(
          latitude: 6.0002,
          longitude: 126,
          timestamp: start.add(const Duration(seconds: 2)),
          speed: 2,
          heading: 230,
        ),
      );

      expect(first!.headingDegrees, closeTo(10, 1));
      expect(flipped!.headingDegrees, closeTo(10, 1));
      expect(confirmed!.headingDegrees, closeTo(230, 1));
    });

    test('ignores GPS heading when the fix is below walking speed', () {
      final filter = NavigationLocationFilter();
      final result = filter.add(
        _position(
          latitude: 6,
          longitude: 126,
          timestamp: DateTime.now(),
          speed: 0,
          heading: 270,
        ),
      );

      expect(result, isNotNull);
      expect(result!.headingDegrees, isNull);
      expect(result.speedMetersPerSecond, lessThan(0.8));
    });

    test('expires a stale heading after the device stops moving', () async {
      final filter = NavigationLocationFilter(
        config: const NavigationLocationFilterConfig(
          headingStaleAfter: Duration(milliseconds: 50),
        ),
      );
      final start = DateTime.now();
      final moving = filter.add(
        _position(
          latitude: 6,
          longitude: 126,
          timestamp: start,
          speed: 2,
          heading: 90,
        ),
      );
      expect(moving!.headingDegrees, closeTo(90, 1));

      await Future<void>.delayed(const Duration(milliseconds: 80));
      final stationary = filter.add(
        _position(
          latitude: 6.00001,
          longitude: 126,
          timestamp: start.add(const Duration(seconds: 3)),
          speed: 0,
        ),
      );
      expect(stationary, isNotNull);
      expect(stationary!.headingDegrees, isNull);
    });
  });

  group('RouteMatcher', () {
    test('projects a position and calculates route progress', () {
      final matcher = RouteMatcher(const [
        LatLng(0, 0),
        LatLng(0, 0.01),
        LatLng(0.01, 0.01),
      ], routeDistanceMeters: 2000);

      final match = matcher.match(const LatLng(0.0001, 0.005));

      expect(match, isNotNull);
      expect(match!.segmentIndex, 0);
      expect(match.distanceToRouteMeters, closeTo(11, 3));
      expect(match.progress, closeTo(0.28, 0.03));
      expect(match.remainingDistanceMeters, closeTo(1440, 40));
    });

    test('treats a zero-length route as complete', () {
      final matcher = RouteMatcher(const [LatLng(1, 2), LatLng(1, 2)]);

      final match = matcher.match(const LatLng(1, 2));

      expect(match, isNotNull);
      expect(match!.progress, 1);
      expect(match.remainingDistanceMeters, 0);
    });

    test('builds completed and remaining route sections', () {
      final route = const [LatLng(0, 0), LatLng(0, 0.01), LatLng(0.01, 0.01)];
      final matcher = RouteMatcher(route, routeDistanceMeters: 2000);
      final match = matcher.match(const LatLng(0.0001, 0.005))!;

      final completed = completedRoutePoints(route, match);
      final remaining = remainingRoutePoints(route, match);

      expect(completed.length, greaterThanOrEqualTo(2));
      expect(remaining.length, greaterThanOrEqualTo(2));
      expect(completed.last.latitude, closeTo(0, 0.0001));
      expect(remaining.first.latitude, closeTo(0, 0.0001));
    });
  });
}
