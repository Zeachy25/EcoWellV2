import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/device_heading_service.dart';
import '../../data/services/navigation_location_filter.dart';
import '../../data/services/route_service.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/heading_provider.dart';
import '../../providers/location_tracking_provider.dart';
import '../shared/fence_overlay.dart';
import '../shared/route_line.dart';
import 'live_navigation_session.dart';
import 'route_progress.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const NavigationScreen({super.key, required this.spaceId});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _locationIcon;
  BitmapDescriptor? _locationIconPlain;
  StreamSubscription<double>? _headingSubscription;
  LiveNavigationState _navigationState = const LiveNavigationState();
  StreamSubscription<LiveNavigationState>? _sessionSubscription;
  Timer? _markerTimer;
  LatLng? _displayPosition;
  double? _displayHeading;
  double? _targetHeading;
  LatLng? _markerAnimationFrom;
  LatLng? _markerAnimationTo;
  double? _markerAnimationFromHeading;
  DateTime? _markerAnimationStarted;
  bool _trackingCamera = true;
  bool _cameraMoveInFlight = false;
  bool _programmaticCameraMove = false;
  bool _initialCameraFit = false;
  bool _fitPending = false;
  CameraPosition? _queuedCameraPosition;

  GreenSpace get _space {
    final spaces = ref.read(greenSpacesProvider);
    return spaces.firstWhere(
      (space) => space.id == widget.spaceId,
      orElse: () => spaces.first,
    );
  }

  @override
  void initState() {
    super.initState();
    final session = LiveNavigationSession(
      destination: _space,
      locationService: ref.read(locationTrackingServiceProvider),
    );
    _sessionSubscription = session.states.listen(_onNavigationState);
    _session = session;
    unawaited(_buildLocationIcons());
    _headingSubscription = ref
        .read(deviceHeadingProvider)
        .headings
        .listen((_) => _refreshMarkerRotation());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_session.start());
    });
  }

  late final LiveNavigationSession _session;

  @override
  void dispose() {
    _markerTimer?.cancel();
    unawaited(_sessionSubscription?.cancel());
    unawaited(_headingSubscription?.cancel());
    _session.dispose();
    _mapController = null;
    super.dispose();
  }

  void _onNavigationState(LiveNavigationState next) {
    if (!mounted) return;
    final previous = _navigationState;
    setState(() => _navigationState = next);

    final location = next.position;
    if (location != null) _animateMarkerTo(location);

    final routeAvailable =
        !_initialCameraFit &&
        (next.route != null || next.fallbackRoute != null) &&
        (previous.route == null && previous.fallbackRoute == null);
    if (routeAvailable) {
      _fitPending = true;
      _queuedCameraPosition = null;
      unawaited(_drainCameraQueue());
    } else if (location != null && _trackingCamera) {
      _queueCameraForLocation(next);
    }
  }

  Future<void> _buildLocationIcons() async {
    final arrow = await _buildLocationIcon(withArrow: true);
    final plain = await _buildLocationIcon(withArrow: false);
    if (!mounted) return;
    setState(() {
      _locationIcon = arrow;
      _locationIconPlain = plain;
    });
  }

  Future<BitmapDescriptor> _buildLocationIcon({required bool withArrow}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = Offset(32, 32);
    const blue = Color(0xFF4285F4);

    canvas.drawCircle(
      center,
      18,
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, 14, ui.Paint()..color = blue);

    if (withArrow) {
      final arrow = ui.Path()
        ..moveTo(32, 10)
        ..lineTo(25, 27)
        ..lineTo(32, 23)
        ..lineTo(39, 27)
        ..close();
      canvas.drawPath(arrow, ui.Paint()..color = const Color(0xFFFFFFFF));
    }
    canvas.drawCircle(center, 4.5, ui.Paint()..color = blue);

    final image = await recorder.endRecording().toImage(64, 64);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  double? _mergedHeading() {
    final service = ref.read(deviceHeadingProvider);
    final position = _navigationState.position;
    return DeviceHeadingService.resolve(
      compassAvailable: service.available,
      compassHeading: service.heading,
      gpsCourseDegrees: position?.headingDegrees,
      speedMetersPerSecond: position?.speedMetersPerSecond ?? 0,
    );
  }

  void _refreshMarkerRotation() {
    final position = _navigationState.position;
    if (position == null || _displayPosition == null) return;
    _animateMarkerTo(position);
  }

  void _animateMarkerTo(NavigationLocation location) {
    final target = LatLng(location.latitude, location.longitude);
    _targetHeading = _mergedHeading();
    if (_displayPosition == null) {
      setState(() {
        _displayPosition = target;
        _displayHeading = _targetHeading;
      });
      return;
    }

    final from = _displayPosition!;
    final distance = _distanceBetween(from, target);
    final headingChanged = !_sameHeading(_displayHeading, _targetHeading);
    if (distance < 0.2 && !headingChanged) return;

    if (_displayHeading != null && _targetHeading == null) {
      setState(() => _displayHeading = null);
    } else if (_displayHeading == null && _targetHeading != null) {
      setState(() => _displayHeading = _targetHeading);
    }

    _markerTimer?.cancel();
    _markerAnimationFrom = from;
    _markerAnimationTo = target;
    _markerAnimationFromHeading = _displayHeading ?? _targetHeading;
    _markerAnimationStarted = DateTime.now();
    final durationMs = (distance / 18 * 1000).clamp(350, 1500).round();
    final start = _markerAnimationStarted!;
    _markerTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final progress = (elapsed / durationMs).clamp(0.0, 1.0).toDouble();
      final fromPosition = _markerAnimationFrom!;
      final toPosition = _markerAnimationTo!;
      final fromHeading = _markerAnimationFromHeading;
      setState(() {
        _displayPosition = LatLng(
          fromPosition.latitude +
              (toPosition.latitude - fromPosition.latitude) * progress,
          fromPosition.longitude +
              (toPosition.longitude - fromPosition.longitude) * progress,
        );
        if (fromHeading != null && _targetHeading != null) {
          _displayHeading = _normalizeBearing(
            fromHeading + _angleDelta(fromHeading, _targetHeading!) * progress,
          );
        }
      });
      if (progress >= 1) timer.cancel();
    });
  }

  bool _sameHeading(double? first, double? second) {
    if (first == null || second == null) return first == second;
    return _angleDelta(first, second).abs() < 3;
  }

  double _angleDelta(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  double _normalizeBearing(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _distanceBetween(LatLng first, LatLng second) {
    return distanceMeters(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );
  }

  CameraPosition _cameraPositionFor(LiveNavigationState state) {
    final location = state.position!;
    final bearing = _mergedHeading() ?? 0;
    return CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 18,
      bearing: bearing,
    );
  }

  void _queueCameraForLocation(LiveNavigationState state) {
    if (!_trackingCamera || state.position == null || _fitPending) return;
    _queuedCameraPosition = _cameraPositionFor(state);
    unawaited(_drainCameraQueue());
  }

  Future<void> _drainCameraQueue() async {
    if (_cameraMoveInFlight) return;
    final controller = _mapController;
    if (controller == null) return;

    if (_fitPending) {
      if (!_trackingCamera) {
        _fitPending = false;
        return;
      }
      final points =
          _navigationState.route?.points ?? _navigationState.fallbackRoute;
      if (points == null || points.length < 2) {
        _fitPending = false;
        return;
      }
      _fitPending = false;
      _queuedCameraPosition = null;
      _initialCameraFit = true;
      _cameraMoveInFlight = true;
      _programmaticCameraMove = true;
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFor(points), 80),
          duration: const Duration(milliseconds: 700),
        );
      } catch (_) {
      } finally {
        _cameraMoveInFlight = false;
        _programmaticCameraMove = false;
        if (_trackingCamera) unawaited(_drainCameraQueue());
      }
      return;
    }

    final position = _queuedCameraPosition;
    if (position == null) return;
    _queuedCameraPosition = null;
    _cameraMoveInFlight = true;
    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(position),
        duration: const Duration(milliseconds: 650),
      );
    } catch (_) {
    } finally {
      _cameraMoveInFlight = false;
      _programmaticCameraMove = false;
      if (_trackingCamera) unawaited(_drainCameraQueue());
    }
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _recenter() {
    setState(() {
      _trackingCamera = true;
      _fitPending = false;
    });
    final state = _navigationState;
    if (state.position != null) _queueCameraForLocation(state);
  }

  Future<void> _endNavigation() async {
    await _session.stop();
    if (mounted && context.canPop()) context.pop();
  }

  String _statusText(LiveNavigationState state, GreenSpace space, bool inside) {
    if (state.arrived) return 'Arrived at ${space.name}';
    if (state.phase == LiveNavigationPhase.error) {
      return state.errorMessage ?? 'Navigation unavailable';
    }
    if (state.rerouting) return 'Finding a new route…';
    if (state.routeLoading) return 'Planning route to ${space.name}…';
    if (state.offRoute) return 'Off route — reconnecting…';
    if (state.position == null) return 'Waiting for GPS…';
    if (inside) return 'Near ${space.name}';
    return 'Navigate to ${space.name}';
  }

  String _etaText(LiveNavigationState state) {
    if (state.arrived) return 'Arrived';
    final seconds = state.etaSeconds;
    if (seconds == null) return '—';
    if (seconds < 60) return '<1 min';
    return '~${(seconds / 60).ceil()} min';
  }

  double? _remainingDistance(LiveNavigationState state) {
    if (state.remainingDistanceMeters != null) {
      return state.remainingDistanceMeters;
    }
    final position = state.position;
    if (position == null) return null;
    return _distanceBetween(
      LatLng(position.latitude, position.longitude),
      LatLng(_space.latitude, _space.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final space = _space;
    final state = _navigationState;
    final displayPosition = _displayPosition;
    final inside =
        state.arrived ||
        (displayPosition != null &&
            space.fence.contains(
              displayPosition.latitude,
              displayPosition.longitude,
            ));
    final remainingMeters = _remainingDistance(state);
    final routePoints = state.route?.points ?? state.fallbackRoute;
    final routeMatch = state.routeMatch;
    final completedPoints = state.route != null && routeMatch != null
        ? completedRoutePoints(state.route!.points, routeMatch)
        : null;
    final remainingPoints = state.route != null && routeMatch != null
        ? remainingRoutePoints(state.route!.points, routeMatch)
        : null;
    final statusText = _statusText(state, space, inside);
    final markerHeading =
        _displayHeading ?? state.position?.headingDegrees;
    final hasHeading = markerHeading != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1927),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  displayPosition ??
                  (state.position == null
                      ? LatLng(space.latitude, space.longitude)
                      : LatLng(
                          state.position!.latitude,
                          state.position!.longitude,
                        )),
              zoom: 18,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              final current = _navigationState;
              if ((current.route != null || current.fallbackRoute != null) &&
                  !_initialCameraFit) {
                _fitPending = true;
                _queuedCameraPosition = null;
                unawaited(_drainCameraQueue());
              } else if (current.position != null) {
                _queueCameraForLocation(current);
              }
            },
            onCameraMoveStarted: () {
              if (_programmaticCameraMove) return;
              if (_trackingCamera) setState(() => _trackingCamera = false);
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
              if (displayPosition != null)
                Marker(
                  markerId: const MarkerId('you'),
                  position: displayPosition,
                  icon: (hasHeading
                              ? _locationIcon
                              : _locationIconPlain) ??
                          BitmapDescriptor.defaultMarker,
                  rotation: hasHeading ? markerHeading : 0,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  zIndexInt: 100,
                ),
            },
            circles: {
              if (FenceOverlay.circleFor(space) case final Circle zone) zone,
            },
            polygons: {
              if (FenceOverlay.polygonFor(space) case final Polygon zone) zone,
            },
            polylines: {
              if (RouteLine.polyline(
                    id: 'nav-route',
                    points: routePoints,
                    zIndex: 4,
                    jointTypeRound: true,
                  )
                  case final Polyline planned)
                planned,
              if (completedPoints != null && completedPoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('nav-route-completed'),
                  points: completedPoints,
                  color: const Color(0xFF7E8B95),
                  width: RouteLine.plannedWidth,
                  jointType: JointType.round,
                  zIndex: 5,
                ),
              if (remainingPoints != null && remainingPoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('nav-route-remaining'),
                  points: remainingPoints,
                  color: RouteLine.plannedColor,
                  width: RouteLine.plannedWidth,
                  jointType: JointType.round,
                  zIndex: 6,
                ),
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => unawaited(_endNavigation()),
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
                          state.arrived
                              ? Icons.check_circle_rounded
                              : Icons.directions_walk_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: Responsive.size(context, 8)),
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13),
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestDark,
                            ),
                          ),
                        ),
                        if (remainingMeters != null)
                          Text(
                            state.arrived
                                ? 'Arrived'
                                : formatGeoDistance(remainingMeters),
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
          if (state.errorMessage != null &&
              state.phase != LiveNavigationPhase.stopped)
            Positioned(
              top: MediaQuery.of(context).padding.top + 66,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.forestDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (state.nextStep != null && !state.arrived)
            Positioned(
              left: 16,
              right: 78,
              bottom: 188,
              child: _InstructionBanner(step: state.nextStep!),
            ),
          Positioned(
            right: 16,
            bottom: state.nextStep == null ? 180 : 250,
            child: _CircleButton(
              icon: _trackingCamera
                  ? Icons.my_location_rounded
                  : Icons.explore_rounded,
              onTap: _recenter,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: EdgeInsets.all(Responsive.size(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.radius(context, 20),
                ),
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
                        value: _etaText(state),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => unawaited(_endNavigation()),
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

class _InstructionBanner extends StatelessWidget {
  final OrsRouteStep step;

  const _InstructionBanner({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _iconForManeuver(step.maneuverType),
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.instruction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.forestDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForManeuver(String? type) {
    final normalized = type?.toLowerCase() ?? '';
    if (normalized.contains('left')) return Icons.turn_left_rounded;
    if (normalized.contains('right')) return Icons.turn_right_rounded;
    if (normalized.contains('arrive')) return Icons.flag_rounded;
    if (normalized.contains('roundabout') || normalized.contains('rotary')) {
      return Icons.turn_slight_right_rounded;
    }
    return Icons.straight_rounded;
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
