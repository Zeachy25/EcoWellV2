import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ecowell/data/services/location_tracking_service.dart';
import 'package:ecowell/data/services/navigation_location_filter.dart';
import 'package:ecowell/data/services/route_service.dart';
import 'package:ecowell/features/navigation/live_navigation_session.dart';
import 'package:ecowell/models/green_space.dart';

class _FakeLocationService extends LocationTrackingService {
  _FakeLocationService() : super();

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  Position? current;
  int acquireCount = 0;
  int releaseCount = 0;

  @override
  Stream<Position> get positions => _controller.stream;

  @override
  Position? get lastPosition => current;

  @override
  Future<LocationTrackingLeaseResult> acquireWithLease() async {
    acquireCount++;
    return LocationTrackingLeaseResult(
      status: LocationTrackingStatus.started,
      lease: LocationTrackingLease(id: acquireCount, generation: acquireCount),
    );
  }

  @override
  Future<void> release([LocationTrackingLease? lease]) async {
    if (releaseCount < acquireCount) releaseCount++;
  }

  void emit(Position position) {
    current = position;
    _controller.add(position);
  }

  Future<void> close() => _controller.close();
}

Position _position(
  double latitude,
  double longitude,
  DateTime timestamp, {
  double speed = 1,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 5,
    speed: speed,
    speedAccuracy: 1,
  );
}

GreenSpace _space() {
  return const GreenSpace(
    id: 'park',
    name: 'Test Park',
    description: '',
    category: 'Park',
    address: '',
    latitude: 0.01,
    longitude: 0,
    radiusMeters: 100,
    amenities: [],
  );
}

OrsRoute _route() {
  return const OrsRoute(
    points: [LatLng(0, 0), LatLng(0.01, 0)],
    distanceMeters: 1113,
    durationSeconds: 600,
  );
}

NavigationLocationFilter _filter() {
  return NavigationLocationFilter(
    config: const NavigationLocationFilterConfig(
      maxJumpMeters: 2000,
      positionSmoothingFactor: 1,
    ),
  );
}

Future<void> _flush() {
  return Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'stops and reports arrival after reaching the destination fence',
    () async {
      final service = _FakeLocationService();
      final space = _space();
      final session = LiveNavigationSession(
        destination: space,
        locationService: service,
        locationFilter: _filter(),
        routeFetcher:
            ({
              required originLat,
              required originLng,
              required destLat,
              required destLng,
            }) async => _route(),
      );

      final arrived = session.states.firstWhere((state) => state.arrived);
      await session.start();
      final start = DateTime.now();
      service.emit(_position(0, 0, start));
      await _flush();
      await _waitFor(() => session.state.route != null);
      service.emit(_position(0.01, 0, start.add(const Duration(seconds: 2))));
      await arrived.timeout(const Duration(seconds: 2));

      expect(session.state.phase, LiveNavigationPhase.arrived);
      expect(service.acquireCount, 1);
      expect(service.releaseCount, 1);
      session.dispose();
      await service.close();
    },
  );

  test('confirms an off-route fix and requests a replacement route', () async {
    final service = _FakeLocationService();
    final requests = <String>[];
    final session = LiveNavigationSession(
      destination: _space(),
      locationService: service,
      locationFilter: _filter(),
      config: const LiveNavigationConfig(
        offRouteThresholdMeters: 10,
        offRouteConfirmationSeconds: 0,
        offRouteConfirmationUpdates: 1,
        rerouteCooldown: Duration.zero,
      ),
      routeFetcher:
          ({
            required originLat,
            required originLng,
            required destLat,
            required destLng,
          }) async {
            requests.add('$originLat,$originLng');
            return _route();
          },
    );

    await session.start();
    final start = DateTime.now();
    service.emit(_position(0, 0, start));
    await _waitFor(() => session.state.route != null);
    service.emit(_position(-0.0001, 0, start.add(const Duration(seconds: 2))));
    await _waitFor(() => requests.isNotEmpty);
    service.emit(_position(-0.0001, 0, start.add(const Duration(seconds: 4))));
    await _waitFor(() => requests.length >= 2);

    expect(requests.length, greaterThanOrEqualTo(2));
    expect(session.state.offRoute, isTrue);
    await session.stop();
    await service.close();
  });

  test('stops when the location stream ends', () async {
    final service = _FakeLocationService();
    final session = LiveNavigationSession(
      destination: _space(),
      locationService: service,
      locationFilter: _filter(),
      routeFetcher:
          ({
            required originLat,
            required originLng,
            required destLat,
            required destLng,
          }) async => _route(),
    );

    final failed = session.states.firstWhere(
      (state) => state.phase == LiveNavigationPhase.error,
    );
    await session.start();
    await service.close();
    await failed.timeout(const Duration(seconds: 2));
    await _waitFor(() => service.releaseCount == 1);

    expect(session.state.errorMessage, isNotNull);
    expect(service.releaseCount, 1);
    session.dispose();
  });

  test('uses the direct fallback and still detects arrival', () async {
    final service = _FakeLocationService();
    final session = LiveNavigationSession(
      destination: _space(),
      locationService: service,
      locationFilter: _filter(),
      config: const LiveNavigationConfig(arrivalProgress: 0.95),
      routeFetcher:
          ({
            required originLat,
            required originLng,
            required destLat,
            required destLng,
          }) async => null,
    );

    final arrived = session.states.firstWhere((state) => state.arrived);
    await session.start();
    final start = DateTime.now();
    service.emit(_position(0, 0, start));
    await _waitFor(() => session.state.fallbackRoute != null);
    service.emit(_position(0.01, 0, start.add(const Duration(seconds: 2))));
    await arrived.timeout(const Duration(seconds: 2));

    expect(session.state.fallbackRoute, isNotNull);
    expect(session.state.arrived, isTrue);
    session.dispose();
    await service.close();
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  if (!condition()) fail('Condition did not become true in time');
}
