import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ecowell/data/services/location_tracking_service.dart';
import 'package:ecowell/data/services/navigation_location_filter.dart';
import 'package:ecowell/features/activities/walk/walk_location_pipeline.dart';
import 'package:ecowell/models/walk_record.dart';

class _FakeLocationService extends LocationTrackingService {
  _FakeLocationService({this.status = LocationTrackingStatus.started});

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  final LocationTrackingStatus status;
  Position? current;
  int acquireCount = 0;
  int releaseCount = 0;
  final List<LocationTrackingLease> issued = <LocationTrackingLease>[];

  @override
  Stream<Position> get positions => _controller.stream;

  @override
  Position? get lastPosition => current;

  @override
  Future<LocationTrackingLeaseResult> acquireWithLease() async {
    acquireCount++;
    if (status != LocationTrackingStatus.started) {
      return LocationTrackingLeaseResult(status: status, lease: null);
    }
    final lease = LocationTrackingLease(id: acquireCount, generation: acquireCount);
    issued.add(lease);
    return LocationTrackingLeaseResult(
      status: LocationTrackingStatus.started,
      lease: lease,
    );
  }

  @override
  Future<void> release([LocationTrackingLease? lease]) async {
    releaseCount++;
  }

  void emit(Position position) {
    current = position;
    _controller.add(position);
  }

  void fail(Object error) => _controller.addError(error);

  void done() => _controller.close();

  Future<void> close() => _controller.close();
}

Position _position({
  double latitude = 7.2,
  double longitude = 125.4,
  double accuracy = 5,
  double speed = 1,
  double heading = 90,
  double headingAccuracy = 5,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: accuracy,
    altitude: 12,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: headingAccuracy,
    speed: speed,
    speedAccuracy: 1,
  );
}

NavigationLocationFilter _filter() {
  return NavigationLocationFilter(
    config: const NavigationLocationFilterConfig(
      positionSmoothingFactor: 1,
      maxJumpMeters: 5000,
    ),
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('WalkLocationPipeline', () {
    test('acquires a lease and republishes accepted fixes', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final points = <GeoPoint>[];
      pipeline.points.listen(points.add);

      final result = await pipeline.start();
      await _flush();

      expect(result.status, LocationTrackingStatus.started);
      expect(service.acquireCount, 1);
      expect(pipeline.isActive, isTrue);

      service.emit(_position(latitude: 7.2, longitude: 125.4));
      await _flush();

      expect(points, hasLength(1));
      expect(points.single.latitude, closeTo(7.2, 1e-9));
      expect(points.single.longitude, closeTo(125.4, 1e-9));
      expect(points.single.altitude, 12);
      expect(pipeline.lastAccepted, isNotNull);

      await pipeline.stop();
      await service.close();
    });

    test('rejects low-accuracy fixes instead of recording them', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final points = <GeoPoint>[];
      pipeline.points.listen(points.add);

      await pipeline.start();
      service.emit(_position(accuracy: 400));
      await _flush();

      expect(points, isEmpty);
      expect(pipeline.lastAccepted, isNull);

      await pipeline.stop();
      await service.close();
    });

    test('rejects non-monotonic and stale timestamps', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final points = <GeoPoint>[];
      pipeline.points.listen(points.add);

      await pipeline.start();
      final now = DateTime.now();
      service.emit(_position(latitude: 1, timestamp: now));
      await _flush();
      service.emit(_position(latitude: 2, timestamp: now));
      await _flush();
      service.emit(
        _position(latitude: 3, timestamp: now.subtract(const Duration(minutes: 5))),
      );
      await _flush();

      expect(points, hasLength(1));
      expect(points.single.latitude, closeTo(1, 1e-9));

      await pipeline.stop();
      await service.close();
    });

    test('seeds from the cached last position on start', () async {
      final service = _FakeLocationService()..current = _position(latitude: 5);
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final points = <GeoPoint>[];
      pipeline.points.listen(points.add);

      await pipeline.start();
      await _flush();

      expect(points, hasLength(1));
      expect(points.single.latitude, closeTo(5, 1e-9));

      await pipeline.stop();
      await service.close();
    });

    test('concurrent starts share a single lease', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );

      await Future.wait([pipeline.start(), pipeline.start(), pipeline.start()]);

      expect(service.acquireCount, 1);
      expect(service.issued, hasLength(1));

      await pipeline.stop();
      await service.close();
    });

    test('stop releases the lease, closes the stream, and is idempotent', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      await pipeline.start();

      await pipeline.stop();
      await pipeline.stop();

      expect(service.releaseCount, 1);
      expect(pipeline.isActive, isFalse);
      expect(pipeline.lastAccepted, isNull);

      await service.close();
    });

    test('does not acquire when the service reports failure', () async {
      final service = _FakeLocationService(
        status: LocationTrackingStatus.permissionDenied,
      );
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );

      final result = await pipeline.start();

      expect(result.status, LocationTrackingStatus.permissionDenied);
      expect(result.lease, isNull);
      expect(pipeline.isActive, isFalse);
      expect(service.releaseCount, 0);

      await service.close();
    });

    test('releases the lease when the source stream errors', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      await pipeline.start();

      service.fail(StateError('gps died'));
      await _flush();

      expect(pipeline.isActive, isFalse);
      expect(service.releaseCount, 1);

      await service.close();
    });

    test('releases the lease when the source stream closes', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      await pipeline.start();

      service.done();
      await _flush();

      expect(pipeline.isActive, isFalse);
      expect(service.releaseCount, 1);
    });

    test('ingest feeds the shared filter state and the point stream', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final points = <GeoPoint>[];
      pipeline.points.listen(points.add);
      await pipeline.start();

      final now = DateTime.now();
      final accepted = pipeline.ingest(
        _position(latitude: 7.3, timestamp: now),
      );
      await _flush();
      expect(accepted, isNotNull);
      expect(points, hasLength(1));

      // A repeat of the same timestamp is rejected by the monotonic guard,
      // proving the filter state is shared with the streamed path.
      final rejected = pipeline.ingest(
        _position(latitude: 7.31, timestamp: now),
      );
      await _flush();
      expect(rejected, isNull);
      expect(points, hasLength(1));

      await pipeline.stop();
      await service.close();
    });

    test('publishes accepted fixes with accuracy, heading, and speed', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: _filter(),
      );
      final locations = <NavigationLocation>[];
      pipeline.locations.listen(locations.add);
      await pipeline.start();

      // Streamed fix: the map needs more than coordinates to move the dot.
      service.emit(
        _position(
          latitude: 7.2,
          longitude: 125.4,
          accuracy: 8,
          speed: 1.4,
          heading: 120,
        ),
      );
      await _flush();

      expect(locations, hasLength(1));
      expect(locations.single.latitude, closeTo(7.2, 1e-9));
      expect(locations.single.longitude, closeTo(125.4, 1e-9));
      expect(locations.single.accuracyMeters, 8);
      expect(locations.single.speedMetersPerSecond, closeTo(1.4, 1e-9));
      expect(locations.single.headingDegrees, closeTo(120, 1e-9));

      // A directly ingested fix (the startup seed) must reach the map too.
      // The timestamp must be at least a millisecond later, otherwise the
      // filter sees zero elapsed time and rejects it as a duplicate.
      final seeded = pipeline.ingest(
        _position(
          latitude: 7.205,
          accuracy: 6,
          timestamp: DateTime.now().add(const Duration(milliseconds: 500)),
        ),
      );
      await _flush();
      expect(seeded, isNotNull);
      expect(locations, hasLength(2));
      expect(locations.last.latitude, closeTo(7.205, 1e-9));
      expect(locations.last.accuracyMeters, 6);

      await pipeline.stop();
      await service.close();
    });

    test('does not publish rejected fixes to the map', () async {
      final service = _FakeLocationService();
      final pipeline = WalkLocationPipeline(
        locationService: service,
        filter: NavigationLocationFilter(
          config: const NavigationLocationFilterConfig(
            positionSmoothingFactor: 1,
            maxJumpMeters: 5000,
            maxAccuracyMeters: 20,
          ),
        ),
      );
      final locations = <NavigationLocation>[];
      final points = <GeoPoint>[];
      pipeline.locations.listen(locations.add);
      pipeline.points.listen(points.add);
      await pipeline.start();

      service.emit(_position(accuracy: 5));
      await _flush();
      expect(locations, hasLength(1));
      expect(points, hasLength(1));

      // Too inaccurate to trust, so the dot must not jump.
      service.emit(
        _position(latitude: 7.21, accuracy: 90, timestamp: DateTime.now()),
      );
      await _flush();
      expect(locations, hasLength(1));
      expect(points, hasLength(1));

      await pipeline.stop();
      await service.close();
    });
  });
}
