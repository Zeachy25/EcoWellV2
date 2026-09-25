import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/route_service.dart';
import '../../models/geo_fence.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/geofence_provider.dart';

/// Google Maps-style foot navigation to a green space. Shows the walking
/// route (OpenRouteService) from your current position to the place's
/// geofence and live-follows your location on the map. Entering the geofence
/// is handled globally by the geofence listener (triggers the pre-assessment).
class NavigationScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const NavigationScreen({super.key, required this.spaceId});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _locationIcon;
  bool _trackingCamera = true;
  bool _pendingProgrammaticMove = false;
  bool _routeRequested = false;
  bool _routeLoading = false;
  OrsRoute? _route;
  List<LatLng>? _fallbackRoute;

  @override
  void initState() {
    super.initState();
    _buildLocationIcon().then((icon) {
      if (mounted) setState(() => _locationIcon = icon);
    });
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  GreenSpace get _space {
    final spaces = ref.read(greenSpacesProvider);
    return spaces.firstWhere(
      (s) => s.id == widget.spaceId,
      orElse: () => spaces.first,
    );
  }

  Future<BitmapDescriptor> _buildLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = Offset(32, 32);
    final blue = const Color(0xFF4285F4);

    canvas.drawCircle(
      center,
      18,
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, 14, ui.Paint()..color = blue);

    final arrow = ui.Path()
      ..moveTo(32, 10)
      ..lineTo(25, 27)
      ..lineTo(32, 23)
      ..lineTo(39, 27)
      ..close();
    canvas.drawPath(arrow, ui.Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(center, 4.5, ui.Paint()..color = blue);

    final image = await recorder.endRecording().toImage(64, 64);
    final Uint8List bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  Future<void> _planRoute(double lat, double lng) async {
    final space = _space;
    setState(() => _routeLoading = true);
    final route = await fetchRoute(
      originLat: lat,
      originLng: lng,
      destLat: space.latitude,
      destLng: space.longitude,
    );
    if (!mounted || !_routeRequested) return;
    setState(() {
      _routeLoading = false;
      _route = route;
      if (route == null) {
        _fallbackRoute = straightLineRoute(
          originLat: lat,
          originLng: lng,
          destLat: space.latitude,
          destLng: space.longitude,
        );
      }
    });
    if (_trackingCamera) _fitCameraToRoute();
  }

  void _fitCameraToRoute() {
    final mapController = _mapController;
    if (mapController == null) return;
    final points = _route?.points ?? _fallbackRoute;
    if (points == null || points.isEmpty) return;
    final bounds = _boundsFor(points);
    _pendingProgrammaticMove = true;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _recenter() {
    setState(() => _trackingCamera = true);
    final pos = ref.read(geofenceProvider).position;
    final mapController = _mapController;
    if (pos != null && mapController != null) {
      _pendingProgrammaticMove = true;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 17,
            bearing: pos.heading,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = _space;
    final geofence = ref.watch(geofenceProvider);
    final pos = geofence.position;

    ref.listen<GeofenceState>(geofenceProvider, (previous, next) {
      final p = next.position;
      if (p == null) return;
      if (_trackingCamera && _mapController != null) {
        _pendingProgrammaticMove = true;
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(p.latitude, p.longitude),
              zoom: 17,
              bearing: p.heading,
            ),
          ),
        );
      }
      if (!_routeRequested && mounted) {
        _routeRequested = true;
        _planRoute(p.latitude, p.longitude);
      }
    });

    if (pos != null && !_routeRequested) {
      _routeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _planRoute(pos.latitude, pos.longitude);
      });
    }

    final inside = pos != null &&
        space.fence.contains(pos.latitude, pos.longitude);

    final remainingMeters = pos == null
        ? null
        : distanceMeters(
            pos.latitude,
            pos.longitude,
            space.latitude,
            space.longitude,
          );

    String? etaText;
    final route = _route;
    if (remainingMeters != null && route != null && route.distanceMeters > 0) {
      final ratio = (remainingMeters / route.distanceMeters).clamp(0.0, 1.0);
      final remainingSeconds = route.durationSeconds * ratio;
      final minutes = (remainingSeconds / 60).round();
      etaText = '~$minutes min';
    }

    final routePoints = _route?.points ?? _fallbackRoute;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1927),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pos != null
                  ? LatLng(pos.latitude, pos.longitude)
                  : LatLng(space.latitude, space.longitude),
              zoom: 15,
            ),
            onMapCreated: (c) {
              _mapController = c;
              final current = ref.read(geofenceProvider).position;
              if (current != null) {
                c.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(current.latitude, current.longitude),
                      zoom: 17,
                      bearing: current.heading,
                    ),
                  ),
                );
              }
            },
            onCameraMoveStarted: () {
              if (_pendingProgrammaticMove) {
                _pendingProgrammaticMove = false;
                return;
              }
              if (_trackingCamera) {
                setState(() => _trackingCamera = false);
              }
            },
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(space.latitude, space.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: InfoWindow(title: space.name),
              ),
              if (pos != null)
                Marker(
                  markerId: const MarkerId('you'),
                  position: LatLng(pos.latitude, pos.longitude),
                  icon: _locationIcon ?? BitmapDescriptor.defaultMarker,
                  rotation: pos.heading,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  zIndexInt: 100,
                ),
            },
            circles: {
              if (pos != null)
                Circle(
                  circleId: const CircleId('location-accuracy'),
                  center: LatLng(pos.latitude, pos.longitude),
                  radius: pos.accuracy > 0 ? pos.accuracy : 10,
                  fillColor: const Color(0x1F4285F4),
                  strokeColor: const Color(0x334285F4),
                  strokeWidth: 1,
                  zIndex: 1,
                ),
              if (space.fence is CircleFence)
                Circle(
                  circleId: const CircleId('destination-zone'),
                  center: LatLng(space.latitude, space.longitude),
                  radius: (space.fence as CircleFence).radiusMeters,
                  fillColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  strokeColor: AppColors.primaryGreen,
                  strokeWidth: 2,
                ),
            },
            polygons: {
              if (space.fence is PolygonFence)
                Polygon(
                  polygonId: const PolygonId('destination-zone'),
                  points: () {
                    final vertices = (space.fence as PolygonFence)
                        .vertices
                        .map((v) => LatLng(v.latitude, v.longitude))
                        .toList();
                    vertices.add(vertices.first);
                    return vertices;
                  }(),
                  fillColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  strokeColor: AppColors.primaryGreen,
                  strokeWidth: 2,
                ),
            },
            polylines: {
              if (routePoints != null && routePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('nav-route'),
                  points: routePoints,
                  color: const Color(0xFF4285F4),
                  width: 5,
                  patterns: _route != null
                      ? const <PatternItem>[]
                      : <PatternItem>[
                          PatternItem.dash(16),
                          PatternItem.gap(12),
                        ],
                  zIndex: 5,
                ),
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top bar: close + route status
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: Responsive.size(context, 48),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.size(context, 14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        Responsive.radius(context, 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          inside
                              ? Icons.check_circle_rounded
                              : Icons.directions_walk_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: Responsive.size(context, 8)),
                        Expanded(
                          child: Text(
                            _routeLoading
                                ? 'Planning route to ${space.name}…'
                                : inside
                                ? 'Arrived at ${space.name}'
                                : 'Navigate to ${space.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13),
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestDark,
                            ),
                          ),
                        ),
                        if (pos != null)
                          Text(
                            formatGeoDistance(remainingMeters ?? 0),
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13),
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recenter follow button
          Positioned(
            right: 16,
            bottom: 180,
            child: _CircleButton(
              icon: _trackingCamera
                  ? Icons.my_location_rounded
                  : Icons.explore_rounded,
              onTap: _recenter,
            ),
          ),

          // Bottom destination card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: EdgeInsets.all(Responsive.size(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: Responsive.size(context, 38),
                        height: Responsive.size(context, 38),
                        decoration: BoxDecoration(
                          color: AppColors.mintLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.nature_people_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: Responsive.size(context, 10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              space.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 15),
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestDark,
                              ),
                            ),
                            Text(
                              space.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 11),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 10)),
                  Row(
                    children: [
                      _MetricChip(
                        icon: Icons.slow_motion_video_rounded,
                        label: 'Remaining',
                        value: remainingMeters == null
                            ? '…'
                            : formatGeoDistance(remainingMeters),
                      ),
                      const SizedBox(width: 8),
                      _MetricChip(
                        icon: Icons.schedule_rounded,
                        label: 'ETA',
                        value: etaText ?? (inside ? 'Arrived' : '—'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('End'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.radius(context, 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: Responsive.size(context, 44),
          height: Responsive.size(context, 44),
          child: Icon(
            icon,
            color: const Color(0xFF163324),
            size: Responsive.size(context, 22),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.size(context, 10),
        vertical: Responsive.size(context, 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryGreen),
          SizedBox(width: Responsive.size(context, 5)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 9),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}