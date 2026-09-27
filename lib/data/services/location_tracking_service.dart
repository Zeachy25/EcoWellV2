import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationTrackingStatus {
  started,
  permissionDenied,
  serviceDisabled,
  error,
}

class LocationTrackingLease {
  const LocationTrackingLease({required this.id, required this.generation});

  final int id;
  final int generation;
}

class LocationTrackingLeaseResult {
  const LocationTrackingLeaseResult({
    required this.status,
    required this.lease,
  });

  final LocationTrackingStatus status;
  final LocationTrackingLease? lease;
}

class LocationTrackingService {
  LocationTrackingService({
    this.distanceFilterMeters = 3,
    this.accuracy = LocationAccuracy.high,
  });

  final double distanceFilterMeters;
  final LocationAccuracy accuracy;

  StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  Future<LocationTrackingStatus>? _startFuture;
  Future<void>? _stopFuture;
  final Set<LocationTrackingLease> _activeLeases = <LocationTrackingLease>{};
  final List<LocationTrackingLease> _legacyLeases = <LocationTrackingLease>[];
  Position? _lastPosition;
  int _nextLeaseId = 0;
  int _streamGeneration = 0;
  bool _disposed = false;

  Stream<Position> get positions => _positionController.stream;
  Position? get lastPosition => _lastPosition;
  bool get isTracking => _positionSubscription != null;

  /// Returns a single fix without starting a tracking stream or requesting
  /// permission. Falls back to the cached fix, then to a short-lived platform
  /// query. Returns `null` when location is unavailable.
  Future<Position?> currentPosition({
    Duration timeLimit = const Duration(seconds: 8),
  }) async {
    if (_disposed) return null;
    if (isTracking) {
      final cached = _lastPosition;
      if (cached != null) return cached;
    }
    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return current;
    } catch (_) {
      return null;
    }
  }

  Future<LocationTrackingLease?> acquireLease() async {
    final result = await acquireWithLease();
    return result.lease;
  }

  Future<LocationTrackingStatus> acquire() async {
    final result = await acquireWithLease();
    final lease = result.lease;
    if (lease != null) _legacyLeases.add(lease);
    return result.status;
  }

  Future<LocationTrackingLeaseResult> acquireWithLease() async {
    if (_disposed) {
      return const LocationTrackingLeaseResult(
        status: LocationTrackingStatus.error,
        lease: null,
      );
    }

    if (isTracking) {
      unawaited(_seedCurrentPosition(_streamGeneration));
      return LocationTrackingLeaseResult(
        status: LocationTrackingStatus.started,
        lease: _registerLease(),
      );
    }

    final activeStart = _startFuture;
    if (activeStart != null) {
      final status = await activeStart;
      if (status != LocationTrackingStatus.started) {
        return LocationTrackingLeaseResult(status: status, lease: null);
      }
      if (!isTracking) {
        return const LocationTrackingLeaseResult(
          status: LocationTrackingStatus.error,
          lease: null,
        );
      }
      unawaited(_seedCurrentPosition(_streamGeneration));
      return LocationTrackingLeaseResult(
        status: LocationTrackingStatus.started,
        lease: _registerLease(),
      );
    }

    final activeStop = _stopFuture;
    if (activeStop != null) await activeStop;
    if (_disposed) {
      return const LocationTrackingLeaseResult(
        status: LocationTrackingStatus.error,
        lease: null,
      );
    }
    if (isTracking) {
      unawaited(_seedCurrentPosition(_streamGeneration));
      return LocationTrackingLeaseResult(
        status: LocationTrackingStatus.started,
        lease: _registerLease(),
      );
    }

    final startFuture = _startFuture ??= _start();
    final status = await startFuture;
    if (identical(_startFuture, startFuture)) _startFuture = null;
    if (status != LocationTrackingStatus.started) {
      return LocationTrackingLeaseResult(status: status, lease: null);
    }
    if (!isTracking) {
      return const LocationTrackingLeaseResult(
        status: LocationTrackingStatus.error,
        lease: null,
      );
    }
    return LocationTrackingLeaseResult(
      status: LocationTrackingStatus.started,
      lease: _registerLease(),
    );
  }

  Future<void> release([LocationTrackingLease? lease]) async {
    LocationTrackingLease? target = lease;
    if (target == null) {
      if (_legacyLeases.isEmpty) return;
      target = _legacyLeases.removeAt(0);
    }

    if (target.generation != _streamGeneration) return;
    if (!_activeLeases.remove(target)) return;
    if (_activeLeases.isEmpty) await _stopStream();
  }

  LocationTrackingLease _registerLease() {
    final lease = LocationTrackingLease(
      id: ++_nextLeaseId,
      generation: _streamGeneration,
    );
    _activeLeases.add(lease);
    return lease;
  }

  Future<LocationTrackingStatus> _start() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (_disposed) return LocationTrackingStatus.error;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return LocationTrackingStatus.permissionDenied;
      }
      if (_disposed) return LocationTrackingStatus.error;
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationTrackingStatus.serviceDisabled;
      }
      if (_disposed) return LocationTrackingStatus.error;

      final generation = ++_streamGeneration;
      final previousController = _positionController;
      final controller = StreamController<Position>.broadcast();
      _positionController = controller;
      if (!previousController.isClosed) {
        unawaited(previousController.close());
      }

      late final StreamSubscription<Position> subscription;
      subscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: accuracy,
              distanceFilter: distanceFilterMeters.round(),
            ),
          ).listen(
            (position) {
              if (identical(subscription, _positionSubscription)) {
                _publish(position, generation: generation);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!identical(subscription, _positionSubscription)) return;
              if (!controller.isClosed) controller.addError(error, stackTrace);
              unawaited(_finishStream(subscription));
            },
            onDone: () {
              if (identical(subscription, _positionSubscription)) {
                unawaited(_finishStream(subscription));
              }
            },
          );
      _positionSubscription = subscription;
      unawaited(_seedCurrentPosition(generation));
      return LocationTrackingStatus.started;
    } catch (_) {
      await _stopStream();
      return LocationTrackingStatus.error;
    }
  }

  Future<void> _seedCurrentPosition(int generation) async {
    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _publish(current, generation: generation);
    } catch (_) {}
  }

  void _publish(Position position, {required int generation}) {
    if (_disposed ||
        _positionSubscription == null ||
        generation != _streamGeneration) {
      return;
    }
    _lastPosition = position;
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
  }

  Future<void> _finishStream(StreamSubscription<Position> subscription) async {
    if (!identical(subscription, _positionSubscription)) return;
    _positionSubscription = null;
    _streamGeneration++;
    _activeLeases.clear();
    _legacyLeases.clear();
    _lastPosition = null;
    final controller = _positionController;
    await subscription.cancel();
    if (!controller.isClosed) await controller.close();
  }

  Future<void> _stopStream() {
    final activeStop = _stopFuture;
    if (activeStop != null) return activeStop;

    final stopFuture = _stopStreamInternal();
    _stopFuture = stopFuture;
    unawaited(
      stopFuture.then<void>(
        (_) {
          if (identical(_stopFuture, stopFuture)) _stopFuture = null;
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_stopFuture, stopFuture)) _stopFuture = null;
        },
      ),
    );
    return stopFuture;
  }

  Future<void> _stopStreamInternal() async {
    final subscription = _positionSubscription;
    final controller = _positionController;
    _positionSubscription = null;
    _streamGeneration++;
    _activeLeases.clear();
    _legacyLeases.clear();
    _lastPosition = null;
    await subscription?.cancel();
    if (!controller.isClosed) await controller.close();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_stopStream());
  }
}
