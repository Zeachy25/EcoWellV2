import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/services/walk_tracker.dart';
import '../../../models/green_space.dart';
import '../../../models/walk_record.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/auth_provider.dart';
import 'screen/walk_summary_screen.dart';
import 'widgets/activity_controls.dart';
import 'widgets/live_hud_overlay.dart';

/// Strava-style GPS activity recorder supporting both Free Exploration
/// and Destination-Guided outdoor tracking.
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

enum _Step { modeSelect, recording, summary }

class _WalkScreenState extends State<WalkScreen> {
  _Step _step = _Step.modeSelect;
  GreenSpace? _destination;
  WalkActivityType _activityType = WalkActivityType.walk;
  WalkRecord? _record;

  void _startActivity({
    GreenSpace? destination,
    WalkActivityType activityType = WalkActivityType.walk,
  }) {
    setState(() {
      _destination = destination;
      _activityType = activityType;
      _step = _Step.recording;
    });
  }

  void _onFinished(WalkRecord record) {
    if (!mounted) return;
    setState(() {
      _record = record;
      _step = _Step.summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.modeSelect => _ModeSelectionStep(onStart: _startActivity),
      _Step.recording => _LiveRecordingStep(
          destination: _destination,
          activityType: _activityType,
          onFinished: _onFinished,
        ),
      _Step.summary => WalkSummaryScreen(
          record: _record!,
          onDone: () => Navigator.of(context).pop(),
        ),
    };
  }
}

class _ModeSelectionStep extends ConsumerStatefulWidget {
  const _ModeSelectionStep({required this.onStart});

  final void Function({
    GreenSpace? destination,
    WalkActivityType activityType,
  }) onStart;

  @override
  ConsumerState<_ModeSelectionStep> createState() =>
      _ModeSelectionStepState();
}

class _ModeSelectionStepState extends ConsumerState<_ModeSelectionStep> {
  WalkActivityType _selectedType = WalkActivityType.walk;

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(greenSpacesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Activity'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Activity Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.forestDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: WalkActivityType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.cardBorder,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryButtonGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestDark.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
                        'OPEN EXPLORATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Icon(Icons.bolt, color: AppColors.streakOrange),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Quick Start ${_selectedType.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track distance, live pace, splits, and elevation wherever you explore.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => widget.onStart(
                      destination: null,
                      activityType: _selectedType,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.forestDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Start Tracking Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Or Select Green Destination',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.forestDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Walk to a verified nature park or sanctuary with arrival detection & Quiet Score rating.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (spaces.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No green destinations configured yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...spaces.map(
              (space) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlacePickerTile(
                  space: space,
                  onTap: () => widget.onStart(
                    destination: space,
                    activityType: _selectedType,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlacePickerTile extends StatelessWidget {
  const _PlacePickerTile({required this.space, required this.onTap});

  final GreenSpace space;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nature_people_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      space.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 13,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Quiet Score ${space.quietScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestDark,
                          ),
                        ),
                        if (space.distanceKm != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${space.distanceKm!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRecordingStep extends ConsumerStatefulWidget {
  const _LiveRecordingStep({
    this.destination,
    required this.activityType,
    required this.onFinished,
  });

  final GreenSpace? destination;
  final WalkActivityType activityType;
  final ValueChanged<WalkRecord> onFinished;

  @override
  ConsumerState<_LiveRecordingStep> createState() => _LiveRecordingStepState();
}

class _LiveRecordingStepState extends ConsumerState<_LiveRecordingStep> {
  final WalkTracker _tracker = WalkTracker();
  bool _arrived = false;
  Timer? _tickTimer;
  ActivitySplit? _latestSplit;

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  double _heading = 0;
  BitmapDescriptor? _locationIcon;
  StreamSubscription<Position>? _fixSubscription;
  bool _isTrackingCamera = true;
  bool _pendingProgrammaticMove = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() {
          _currentPosition = LatLng(last.latitude, last.longitude);
          _heading = last.heading;
        });
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _heading = pos.heading;
        });
      }
    } catch (_) {}
    if (_currentPosition != null && _mapController != null) {
      _pendingProgrammaticMove = true;
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 17),
        ),
      );
    }

    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 6,
      ),
    ).asBroadcastStream();

    GeoPoint? initialPoint;
    final currentPos = _currentPosition;
    if (currentPos != null) {
      initialPoint = GeoPoint(
        latitude: currentPos.latitude,
        longitude: currentPos.longitude,
        timestamp: DateTime.now(),
      );
    }

    _tracker.onPosition = (_) {
      if (mounted) setState(() {});
    };
    _tracker.onArrived = (_) {
      if (mounted) setState(() => _arrived = true);
    };
    _tracker.onSplitCompleted = (split) {
      if (mounted) {
        setState(() => _latestSplit = split);
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _latestSplit == split) {
            setState(() => _latestSplit = null);
          }
        });
      }
    };
    _tracker.onStatusChanged = () {
      if (mounted) setState(() {});
    };

    _tracker.start(
      widget.destination,
      activityType: widget.activityType,
      positionStream: positionStream.map(
        (p) => GeoPoint(
          latitude: p.latitude,
          longitude: p.longitude,
          altitude: p.altitude,
          timestamp: p.timestamp,
        ),
      ),
      initial: initialPoint,
    );

    _fixSubscription = positionStream.listen(_onFix);

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _onFix(Position p) async {
    if (!mounted) return;
    _currentPosition = LatLng(p.latitude, p.longitude);
    _heading = p.heading;
    await _buildLocationIconIfNeeded();
    if (mounted) setState(() {});

    if (mounted &&
        _isTrackingCamera &&
        _mapController != null &&
        _currentPosition != null) {
      _pendingProgrammaticMove = true;
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 17,
            bearing: _heading,
          ),
        ),
      );
    }
  }

  Future<void> _buildLocationIconIfNeeded() async {
    if (_locationIcon != null) return;
    _locationIcon = await _buildLocationIcon();
  }

  Future<BitmapDescriptor> _buildLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = Offset(32, 32);

    canvas.drawCircle(center, 15, ui.Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(center, 9, ui.Paint()..color = AppColors.primaryGreen);
    final notch = ui.Path()
      ..moveTo(32, 6)
      ..lineTo(26, 22)
      ..lineTo(38, 22)
      ..close();
    canvas.drawPath(notch, ui.Paint()..color = const Color(0xFFFFFFFF));

    final image = await recorder.endRecording().toImage(64, 64);
    final Uint8List bytes =
        (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  void _recenterCamera() {
    setState(() => _isTrackingCamera = true);
    if (_currentPosition != null && _mapController != null) {
      _pendingProgrammaticMove = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 17,
            bearing: _heading,
          ),
        ),
      );
    }
  }

  void _finish() {
    final userId = ref.read(authControllerProvider).user?.id ?? 'user-1';
    final record = _tracker.stop(userId: userId);
    if (record == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No GPS location captured yet. Please wait a moment and try again.',
            ),
            backgroundColor: AppColors.streakOrange,
          ),
        );
      }
      return;
    }
    widget.onFinished(record);
  }

  void _discard() {
    _tracker.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _fixSubscription?.cancel();
    _fixSubscription = null;
    _mapController = null;
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _tracker.distanceMeters / 1000;
    final movingDuration = _tracker.movingDuration;

    final trailPoints = _tracker.path
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? _currentPosition!
                  : widget.destination != null
                      ? LatLng(
                          widget.destination!.latitude,
                          widget.destination!.longitude,
                        )
                      : const LatLng(6.95, 126.21),
              zoom: 17,
            ),
            onMapCreated: (c) {
              _mapController = c;
              final pos = _currentPosition;
              if (pos != null) {
                c.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: pos, zoom: 17),
                  ),
                );
                _isTrackingCamera = true;
              }
            },
            onCameraMoveStarted: () {
              if (_pendingProgrammaticMove) {
                _pendingProgrammaticMove = false;
                return;
              }
              if (_isTrackingCamera) {
                setState(() => _isTrackingCamera = false);
              }
            },
            markers: {
              if (widget.destination != null)
                Marker(
                  markerId: const MarkerId('destination'),
                  position: LatLng(
                    widget.destination!.latitude,
                    widget.destination!.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow:
                      InfoWindow(title: widget.destination!.name),
                ),
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('you'),
                  position: _currentPosition!,
                  icon: _locationIcon ?? BitmapDescriptor.defaultMarker,
                  rotation: _heading,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  zIndexInt: 100,
                ),
            },
            circles: {
              if (widget.destination != null)
                Circle(
                  circleId: const CircleId('destination-zone'),
                  center: LatLng(
                    widget.destination!.latitude,
                    widget.destination!.longitude,
                  ),
                  radius: 500,
                  fillColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  strokeColor: AppColors.primaryGreen,
                  strokeWidth: 2,
                ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('walk-casing'),
                points: trailPoints,
                color: const Color(0xFFFFFFFF),
                width: 11,
                jointType: JointType.round,
                zIndex: 10,
              ),
              Polyline(
                polylineId: const PolylineId('walk-route'),
                points: trailPoints,
                color: const Color(0xFF4285F4),
                width: 5,
                jointType: JointType.round,
                zIndex: 11,
              ),
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: LiveHudOverlay(
              activityType: widget.activityType,
              distanceKm: distanceKm,
              movingDuration: movingDuration,
              currentPaceSecondsPerKm: _tracker.currentPaceSecondsPerKm,
              avgPaceSecondsPerKm: _tracker.avgPaceSecondsPerKm,
              calories: _tracker.caloriesBurned,
              elevationGainMeters: _tracker.elevationGainMeters,
              isPaused: _tracker.isPaused,
              latestSplit: _latestSplit,
              destinationName: widget.destination?.name,
            ),
          ),

          if (_arrived && widget.destination != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: _ArrivedBanner(
                destinationName: widget.destination!.name,
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ActivityControls(
              isPaused: _tracker.isPaused,
              onPause: _tracker.pause,
              onResume: _tracker.resume,
              onFinish: _finish,
              onDiscard: _discard,
              onRecenter: _recenterCamera,
              isTrackingCamera: _isTrackingCamera,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivedBanner extends StatelessWidget {
  const _ArrivedBanner({required this.destinationName});

  final String destinationName;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Arrived at $destinationName! 🎉',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}