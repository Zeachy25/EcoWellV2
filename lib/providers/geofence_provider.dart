import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/geo.dart';
import '../models/green_space.dart';
import 'app_providers.dart';

/// Geofence monitoring state.
///
/// Geofenced areas are the developer-defined `GreenSpace` entries from
/// [greenSpacesProvider] - each place has its own [GreenSpace.fence] shape
/// (a radius circle or an arbitrary polygon). This controller streams GPS
/// fixes and detects when the user enters or exits a geofence.
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

  @override
  GeofenceState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const GeofenceState();
  }

  Future<void> startMonitoring() async {
    if (state.monitoring) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = const GeofenceState(permissionDenied: true);
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      state = const GeofenceState(serviceDisabled: true);
      return;
    }

    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(
      _updateInside,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('EcoWell geofence stream error: $error');
      },
    );

    state = GeofenceState(
      monitoring: true,
      position: state.position,
      insideSpace: state.insideSpace,
    );

    // Grab an immediate fix so "started already inside a fence" triggers the
    // arrival flow right away instead of waiting for the first stream event.
    unawaited(_seedFromLastPosition());
  }

  Future<void> _seedFromLastPosition() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos != null) _updateInside(pos);
  }

  Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    _subscription = null;
    state = const GeofenceState();
  }

  void _updateInside(Position position) {
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

  /// Dev/test hook: feeds a synthetic position through the same detection
  /// path as a real GPS fix, so enter/exit behavior can be exercised on
  /// demand (no walking required).
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