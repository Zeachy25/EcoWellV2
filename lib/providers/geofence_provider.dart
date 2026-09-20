import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/geo.dart';
import '../models/green_space.dart';
import 'app_providers.dart';

/// Geofence monitoring state.
///
/// Geofenced areas are the developer-defined `GreenSpace` entries from
/// [greenSpacesProvider] - each place has its own [GreenSpace.radiusMeters]
/// geofence radius. This controller streams GPS fixes and detects when the
/// user enters or exits a geofence circle.
class GeofenceState {
  final Position? position;
  final GreenSpace? insideSpace;
  final bool monitoring;
  final bool permissionDenied;

  const GeofenceState({
    this.position,
    this.insideSpace,
    this.monitoring = false,
    this.permissionDenied = false,
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
    if (!await Geolocator.isLocationServiceEnabled()) return;

    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(_updateInside);

    state = GeofenceState(
      monitoring: true,
      position: state.position,
      insideSpace: state.insideSpace,
    );
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
    final inside = nearest != null && minDistance <= nearest.radiusMeters;
    state = GeofenceState(
      position: position,
      insideSpace: inside ? nearest : null,
      monitoring: true,
    );
  }
}

final geofenceProvider = NotifierProvider<GeofenceController, GeofenceState>(
  GeofenceController.new,
);
