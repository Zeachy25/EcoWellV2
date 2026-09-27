import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../models/walk_record.dart';

/// Shared map rendering for recorded (historical) walk paths.
///
/// Used by the post-activity summary and the activity detail screen so both
/// show identical bounds fitting, start/finish markers, and route styling.
class WalkHistoryMap extends StatefulWidget {
  const WalkHistoryMap({
    super.key,
    required this.record,
    required this.polylineIdPrefix,
    this.height = 220,
    this.zoom = 14,
    this.boundsPadding = 36,
  });

  final WalkRecord record;
  final String polylineIdPrefix;
  final double height;
  final double zoom;
  final double boundsPadding;

  @override
  State<WalkHistoryMap> createState() => _WalkHistoryMapState();
}

class _WalkHistoryMapState extends State<WalkHistoryMap> {
  GoogleMapController? _mapController;
  bool _fitted = false;

  List<LatLng> get _pathPoints => widget.record.path
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  LatLng get _fallbackTarget {
    final destination = widget.record.destination;
    return destination != null
        ? LatLng(destination.latitude, destination.longitude)
        : const LatLng(6.95, 126.21);
  }

  @override
  void didUpdateWidget(WalkHistoryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) _fitted = false;
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    if (points.isEmpty) {
      final target = _fallbackTarget;
      return LatLngBounds(
        southwest: LatLng(target.latitude - 0.005, target.longitude - 0.005),
        northeast: LatLng(target.latitude + 0.005, target.longitude + 0.005),
      );
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat - 0.002, minLon - 0.002),
      northeast: LatLng(maxLat + 0.002, maxLon + 0.002),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _pathPoints;
    final prefix = widget.polylineIdPrefix;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: points.isNotEmpty ? points.first : _fallbackTarget,
            zoom: widget.zoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _fitBounds(points);
          },
          markers: {
            if (points.isNotEmpty) ...[
              Marker(
                markerId: MarkerId('$prefix-start'),
                position: points.first,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Start'),
              ),
              Marker(
                markerId: MarkerId('$prefix-finish'),
                position: points.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: const InfoWindow(title: 'Finish'),
              ),
            ],
          },
          polylines: {
            Polyline(
              polylineId: PolylineId('$prefix-glow'),
              points: points,
              color: AppColors.streakOrange.withValues(alpha: 0.3),
              width: 8,
              jointType: JointType.round,
            ),
            Polyline(
              polylineId: PolylineId('$prefix-core'),
              points: points,
              color: AppColors.streakOrange,
              width: 4,
              jointType: JointType.round,
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  void _fitBounds(List<LatLng> points) {
    if (_fitted || _mapController == null || points.isEmpty) return;
    _fitted = true;
    final controller = _mapController;
    if (controller == null) return;
    final bounds = _boundsFor(points);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _mapController == null) return;
      unawaited(
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, widget.boundsPadding),
        ),
      );
    });
  }
}
