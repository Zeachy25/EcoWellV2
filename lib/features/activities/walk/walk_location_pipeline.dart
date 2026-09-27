import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../data/services/location_tracking_service.dart';
import '../../../data/services/navigation_location_filter.dart';
import '../../../models/walk_record.dart';

/// Owns the GPS pipeline for a recorded activity: acquires a shared
/// [LocationTrackingService] lease, validates/smooths incoming fixes through
/// a [NavigationLocationFilter], and republishes the accepted fixes.
///
/// Two views of the same accepted fixes are exposed:
///  * [points] for the [WalkTracker], which only needs coordinates.
///  * [locations] for the live map UI, which also needs accuracy, smoothed
///    heading, and speed.
///
/// Keeping this separate from the map UI means the recorder and the live map
/// consume the exact same filtered fix, and the lease lifecycle is testable
/// without a Google Maps surface.
class WalkLocationPipeline {
  WalkLocationPipeline({
    required this.locationService,
    NavigationLocationFilter? filter,
  }) : _filter = filter ?? NavigationLocationFilter();

  final LocationTrackingService locationService;
  final NavigationLocationFilter _filter;
  final StreamController<GeoPoint> _points =
      StreamController<GeoPoint>.broadcast();
  final StreamController<NavigationLocation> _locations =
      StreamController<NavigationLocation>.broadcast();

  StreamSubscription<Position>? _subscription;
  LocationTrackingLease? _lease;
  Future<LocationTrackingLeaseResult>? _startFuture;
  int _lifecycleSerial = 0;
  NavigationLocation? _lastAccepted;

  /// Accepted fixes, published for the walk tracker.
  Stream<GeoPoint> get points => _points.stream;

  /// Accepted fixes with their accuracy/heading/speed, published for the live
  /// map so the position indicator can follow the user while recording.
  Stream<NavigationLocation> get locations => _locations.stream;

  /// Latest accepted (validated and smoothed) fix, or null before the first
  /// accepted update.
  NavigationLocation? get lastAccepted => _lastAccepted;

  bool get isActive => _lease != null;

  /// Acquires a lease and starts republishing filtered fixes. Safe to call
  /// repeatedly; concurrent callers share one acquisition.
  Future<LocationTrackingLeaseResult> start() {
    final active = _startFuture;
    if (active != null) return active;

    final future = _start();
    _startFuture = future;
    unawaited(
      future.then<void>(
        (_) {
          if (identical(_startFuture, future)) _startFuture = null;
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_startFuture, future)) _startFuture = null;
        },
      ),
    );
    return future;
  }

  Future<LocationTrackingLeaseResult> _start() async {
    if (_points.isClosed || _locations.isClosed) {
      return const LocationTrackingLeaseResult(
        status: LocationTrackingStatus.error,
        lease: null,
      );
    }
    final lifecycle = ++_lifecycleSerial;
    final acquisition = await locationService.acquireWithLease();
    final lease = acquisition.lease;
    if (lifecycle != _lifecycleSerial) {
      if (lease != null) await locationService.release(lease);
      return const LocationTrackingLeaseResult(
        status: LocationTrackingStatus.error,
        lease: null,
      );
    }
    if (acquisition.status != LocationTrackingStatus.started || lease == null) {
      return acquisition;
    }
    _lease = lease;

    late final StreamSubscription<Position> subscription;
    subscription = locationService.positions.listen(
      (position) {
        if (identical(_subscription, subscription)) _accept(position);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_subscription, subscription)) unawaited(stop());
      },
      onDone: () {
        if (identical(_subscription, subscription)) unawaited(stop());
      },
    );
    _subscription = subscription;

    final cached = locationService.lastPosition;
    if (cached != null) _accept(cached);
    return acquisition;
  }

  /// Feeds a fix through the shared filter and republishes it when accepted.
  /// Returns the accepted fix, or `null` if the filter rejected it. Used both
  /// for streamed updates and for the initial seed fix.
  NavigationLocation? ingest(Position position) => _accept(position);

  NavigationLocation? _accept(Position position) {
    if (_points.isClosed || _locations.isClosed) return null;
    final filtered = _filter.add(position);
    if (filtered == null) return null;
    _lastAccepted = filtered;
    _locations.add(filtered);
    _points.add(
      GeoPoint(
        latitude: filtered.latitude,
        longitude: filtered.longitude,
        altitude: position.altitude,
        timestamp: filtered.timestamp,
      ),
    );
    return filtered;
  }

  /// Releases the lease and closes the point stream. Safe to call repeatedly.
  Future<void> stop() async {
    _lifecycleSerial++;
    _startFuture = null;
    final subscription = _subscription;
    _subscription = null;
    final lease = _lease;
    _lease = null;
    _filter.reset();
    _lastAccepted = null;
    await subscription?.cancel();
    if (lease != null) await locationService.release(lease);
    if (!_points.isClosed) await _points.close();
    if (!_locations.isClosed) await _locations.close();
  }
}
