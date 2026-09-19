import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/config/app_config.dart';
import '../core/utils/geo.dart';
import '../data/seed_data.dart';
import '../models/green_space.dart';

class GeofenceState {
  final GreenSpace? insideSpace;
  final bool monitoring;
  final bool permissionDenied;

  const GeofenceState({
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
    for (final space in matiGreenSpaces) {
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
    final inside =
        nearest != null && minDistance <= AppConfig.geofenceRadiusMeters;
    state = GeofenceState(
      insideSpace: inside ? nearest : null,
      monitoring: true,
    );
  }
}

final geofenceProvider =
    NotifierProvider<GeofenceController, GeofenceState>(GeofenceController.new);