import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../models/community_post.dart';
import '../../../../models/walk_record.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_provider.dart';
import '../widgets/splits_chart.dart';

/// Detailed view for inspecting historical GPS activity records.
class WalkDetailScreen extends ConsumerStatefulWidget {
  const WalkDetailScreen({super.key, required this.record});

  final WalkRecord record;

  @override
  ConsumerState<WalkDetailScreen> createState() => _WalkDetailScreenState();
}

class _WalkDetailScreenState extends ConsumerState<WalkDetailScreen> {
  GoogleMapController? _mapController;

  LatLngBounds _computeBounds(List<GeoPoint> path) {
    if (path.isEmpty) {
      final dest = widget.record.destination;
      final lat = dest?.latitude ?? 6.95;
      final lon = dest?.longitude ?? 126.21;
      return LatLngBounds(
        southwest: LatLng(lat - 0.005, lon - 0.005),
        northeast: LatLng(lat + 0.005, lon + 0.005),
      );
    }
    var minLat = path.first.latitude;
    var maxLat = path.first.latitude;
    var minLon = path.first.longitude;
    var maxLon = path.first.longitude;

    for (final p in path) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.002, minLon - 0.002),
      northeast: LatLng(maxLat + 0.002, maxLon + 0.002),
    );
  }

  Future<void> _shareToCommunity() async {
    final authUser = ref.read(authControllerProvider).user;
    final distanceKm =
        (widget.record.distanceMeters / 1000).toStringAsFixed(2);
    final durationStr = _formatDuration(widget.record.activeDuration);
    final locationName = widget.record.destination?.name ?? 'Nature Route';

    final post = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      userId: authUser?.id ?? 'current-user',
      userName: authUser?.name ?? 'Arlene Rollorata',
      userAvatar: authUser?.avatarUrl ?? '',
      locationName: locationName,
      locationAddress:
          widget.record.destination?.address ?? 'Mati City, Davao Oriental',
      rating: widget.record.quietRating?.toDouble() ?? 4.0,
      imageUrl: 'assets/images/Explore.png',
      caption:
          'Explored a $distanceKm km route in $durationStr! '
          '${widget.record.notes ?? ''}',
      likedByPreview: const ['You'],
      likesCount: 1,
      commentsCount: 0,
      sharesCount: 0,
      isLiked: true,
      createdAt: DateTime.now(),
    );

    ref.read(communityProvider.notifier).addUserPost(post);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity shared to Community Feed! 🌿'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = widget.record.distanceMeters / 1000;
    final pathPoints = widget.record.path
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.record.displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareToCommunity,
            tooltip: 'Share to Feed',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // 1. Map Route
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 240,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: pathPoints.isNotEmpty
                      ? pathPoints.first
                      : const LatLng(6.95, 126.21),
                  zoom: 14,
                ),
                onMapCreated: (c) {
                  _mapController = c;
                  if (pathPoints.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          _computeBounds(widget.record.path),
                          36,
                        ),
                      );
                    });
                  }
                },
                markers: {
                  if (pathPoints.isNotEmpty) ...[
                    Marker(
                      markerId: const MarkerId('start'),
                      position: pathPoints.first,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: const InfoWindow(title: 'Start'),
                    ),
                    Marker(
                      markerId: const MarkerId('finish'),
                      position: pathPoints.last,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                      infoWindow: const InfoWindow(title: 'Finish'),
                    ),
                  ],
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('detail-glow'),
                    points: pathPoints,
                    color: AppColors.streakOrange.withValues(alpha: 0.3),
                    width: 8,
                    jointType: JointType.round,
                  ),
                  Polyline(
                    polylineId: const PolylineId('detail-core'),
                    points: pathPoints,
                    color: AppColors.streakOrange,
                    width: 4,
                    jointType: JointType.round,
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Metrics Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.record.activityType.icon,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.record.activityType.label} Analytics',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Distance',
                        value: '${distanceKm.toStringAsFixed(2)} km',
                        icon: Icons.straighten,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Moving Time',
                        value: _formatDuration(widget.record.activeDuration),
                        icon: Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Avg Pace',
                        value: widget.record.formattedAvgPace,
                        icon: Icons.speed,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Calories',
                        value: '${widget.record.caloriesBurned} kcal',
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Elevation Gain',
                        value:
                            '+${widget.record.elevationGainMeters.toStringAsFixed(0)} m',
                        icon: Icons.trending_up,
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Recorded On',
                        value: _fmtDate(widget.record.startedAt),
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Kilometer Splits
          if (widget.record.splits.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kilometer Splits',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SplitsChart(splits: widget.record.splits),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Wellness Impact
          if (widget.record.quietRating != null ||
              widget.record.moodTag != null ||
              widget.record.notes != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wellness Reflection',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.record.quietRating != null)
                    Row(
                      children: [
                        const Text(
                          'Quiet Score: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= widget.record.quietRating!
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.amberRating,
                            size: 18,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.record.quietRating}/5',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  if (widget.record.moodTag != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Feeling: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            widget.record.moodTag!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.record.notes != null &&
                      widget.record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.record.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

String _fmtDate(DateTime d) {
  final months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}