import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ecowell/data/services/location_tracking_service.dart';

Position _position({
  double latitude = 7.2,
  double longitude = 125.4,
  double accuracy = 5,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeLocationService extends LocationTrackingService {
  _FakeLocationService({this.overrideCurrent});

  final Future<Position?> Function(Duration timeLimit)? overrideCurrent;
  int currentPositionCalls = 0;

  @override
  Future<Position?> currentPosition({
    Duration timeLimit = const Duration(seconds: 8),
  }) async {
    currentPositionCalls++;
    final override = overrideCurrent;
    if (override != null) return override(timeLimit);
    return super.currentPosition(timeLimit: timeLimit);
  }
}
void main() {
  group('LocationTrackingService.currentPosition', () {
    test('returns null when disposed without touching the platform', () async {
      final service = _FakeLocationService();
      service.dispose();

      expect(await service.currentPosition(), isNull);
      expect(service.currentPositionCalls, 1);
    });

    test('falls back to a platform query when no cache exists', () async {
      final service = _FakeLocationService(overrideCurrent: (_) async {
        return _position(latitude: 99);
      });
      addTearDown(service.dispose);

      final result = await service.currentPosition();

      expect(service.isTracking, isFalse);
      expect(result?.latitude, 99);
    });

    test('passes the requested time limit through to the platform', () async {
      Duration? seen;
      final service = _FakeLocationService(
        overrideCurrent: (timeLimit) async {
          seen = timeLimit;
          return null;
        },
      );
      addTearDown(service.dispose);

      await service.currentPosition(timeLimit: const Duration(seconds: 2));

      expect(seen, const Duration(seconds: 2));
    });

    test('never starts a tracking stream', () async {
      final service = _FakeLocationService(overrideCurrent: (_) async {
        return _position();
      });
      addTearDown(service.dispose);

      await service.currentPosition();

      expect(service.isTracking, isFalse);
    });
  });
}
