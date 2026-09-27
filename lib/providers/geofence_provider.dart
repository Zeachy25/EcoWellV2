import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/geo.dart';
import '../data/services/location_tracking_service.dart';
import '../models/green_space.dart';
import 'app_providers.dart';
import 'location_tracking_provider.dart';

class GeofenceState {
  final Position? position;
  final GreenSpace? insideSpace;
  final bool monitoring;
  final bool permissionDenied;
  final bool serviceDisabled;

  const GeofenceState({
    this.position,
    this.insideSpace,
    this.monitoring = false,
    this.permissionDenied = false,
    this.serviceDisabled = false,
  });
}

class GeofenceController extends Notifier<GeofenceState> {
  StreamSubscription<Position>? _subscription;
  late LocationTrackingService _locationService;
  LocationTrackingLease? _lease;
  Future<void>? _startFuture;
  int _lifecycleSerial = 0;
  bool _disposed = false;

  @override
  GeofenceState build() {
    _locationService = ref.read(locationTrackingServiceProvider);
    ref.onDispose(() {
      _disposed = true;
      _lifecycleSerial++;
      unawaited(_subscription?.cancel());
      final lease = _lease;
      _lease = null;
      if (lease != null) unawaited(_locationService.release(lease));
    });
    return const GeofenceState();
  }

  Future<void> startMonitoring() {
    if (_subscription != null && _lease != null) return Future<void>.value();
    final active = _startFuture;
    if (active != null) return active;

    final future = _startMonitoring();
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

  Future<void> _startMonitoring() async {
    if (_disposed) return;
    final lifecycle = ++_lifecycleSerial;
    final acquisition = await _locationService.acquireWithLease();
    final lease = acquisition.lease;
    if (_disposed || lifecycle != _lifecycleSerial) {
      if (lease != null) await _locationService.release(lease);
      return;
    }
    if (acquisition.status != LocationTrackingStatus.started || lease == null) {
      state = GeofenceState(
        permissionDenied:
            acquisition.status == LocationTrackingStatus.permissionDenied,
        serviceDisabled:
            acquisition.status == LocationTrackingStatus.serviceDisabled,
      );
      return;
    }

    _lease = lease;
    late final StreamSubscription<Position> subscription;
    subscription = _locationService.positions.listen(
      (position) {
        if (identical(_subscription, subscription)) _updateInside(position);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('EcoWell geofence stream error: $error');
        if (identical(_subscription, subscription)) {
          unawaited(stopMonitoring());
        }
      },
      onDone: () {
        if (identical(_subscription, subscription)) {
          unawaited(stopMonitoring());
        }
      },
    );
    _subscription = subscription;
    state = GeofenceState(
      monitoring: true,
      position: state.position,
      insideSpace: state.insideSpace,
    );

    final lastPosition = _locationService.lastPosition;
    if (lastPosition != null) _updateInside(lastPosition);
  }

  Future<void> stopMonitoring() async {
    final lifecycle = ++_lifecycleSerial;
    _startFuture = null;
    final subscription = _subscription;
    _subscription = null;
    final lease = _lease;
    _lease = null;
    await subscription?.cancel();
    if (lease != null) await _locationService.release(lease);
    if (_disposed || lifecycle != _lifecycleSerial) return;
    state = const GeofenceState();
  }

  void _updateInside(Position position) {
    if (_disposed) return;
    GreenSpace? nearest;
    var minDistance = double.infinity;
    final spaces = ref.read(greenSpacesProvider);
    for (final space in spaces) {
      if (!space.fence.contains(position.latitude, position.longitude)) {
        continue;
      }
      final distance = distanceMeters(
        position.latitude,
        position.longitude,
        space.latitude,
        space.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = space;
      }
    }
    state = GeofenceState(
      position: position,
      insideSpace: nearest,
      monitoring: true,
    );
  }

  void debugInjectPosition({
    required double latitude,
    required double longitude,
  }) {
    _updateInside(
      Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
  }
}

final geofenceProvider = NotifierProvider<GeofenceController, GeofenceState>(
  GeofenceController.new,
);
