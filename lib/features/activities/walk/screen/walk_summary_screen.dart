import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../models/community_post.dart';
import '../../../../models/walk_record.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_provider.dart';
import '../../../../providers/walks_provider.dart';
import '../widgets/splits_chart.dart';

/// Comprehensive post-activity summary and analytics screen.
/// Displays interactive route map, multi-metric performance grid, splits,
/// Quiet Score rating, mindfulness mood check-in, and community sharing.
class WalkSummaryScreen extends ConsumerStatefulWidget {
  const WalkSummaryScreen({
    super.key,
    required this.record,
    required this.onDone,
  });

  final WalkRecord record;
  final VoidCallback onDone;

  @override
  ConsumerState<WalkSummaryScreen> createState() => _WalkSummaryScreenState();
}

class _WalkSummaryScreenState extends ConsumerState<WalkSummaryScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  int _quietScore = 4;
  String? _selectedMood = 'Refreshed';
  bool _isSharing = false;
  GoogleMapController? _mapController;

  static const _moodOptions = ['Refreshed', 'Calm', 'Energized', 'Grounded'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.displayTitle);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  WalkRecord _buildFinalRecord() {
    return WalkRecord(
      id: widget.record.id,
      userId: widget.record.userId,
      destination: widget.record.destination,
      activityType: widget.record.activityType,
      title: _titleController.text.trim().isEmpty
          ? widget.record.displayTitle
          : _titleController.text.trim(),
      startedAt: widget.record.startedAt,
      endedAt: widget.record.endedAt,
      movingDuration: widget.record.movingDuration,
      path: widget.record.path,
      splits: widget.record.splits,
      elevationGainMeters: widget.record.elevationGainMeters,
      caloriesBurned: widget.record.caloriesBurned,
      arrived: widget.record.arrived,
      quietRating: _quietScore,
      moodTag: _selectedMood,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  Future<void> _saveAndFinish() async {
    final finalRecord = _buildFinalRecord();
    ref.read(walksProvider.notifier).addRecord(finalRecord);
    if (!mounted) return;
    widget.onDone();
  }

  Future<void> _shareToCommunity() async {
    setState(() => _isSharing = true);
    final finalRecord = _buildFinalRecord();
    ref.read(walksProvider.notifier).addRecord(finalRecord);

    final authUser = ref.read(authControllerProvider).user;
    final distanceKm = (finalRecord.distanceMeters / 1000).toStringAsFixed(2);
    final durationStr = _formatDuration(finalRecord.activeDuration);
    final locationName = finalRecord.destination?.name ?? 'Nature Trail';

    final post = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      userId: authUser?.id ?? 'current-user',
      userName: authUser?.name ?? 'Arlene Rollorata',
      userAvatar: authUser?.avatarUrl ?? '',
      locationName: locationName,
      locationAddress: finalRecord.destination?.address ?? 'Mati City, Davao Oriental',
      rating: _quietScore.toDouble(),
      imageUrl: 'assets/images/Explore.png',
      caption:
          'Completed a $distanceKm km ${finalRecord.activityType.label.toLowerCase()} in $durationStr! '
          'Feeling $_selectedMood. ${finalRecord.notes ?? ''}',
      likedByPreview: const ['You'],
      likesCount: 1,
      commentsCount: 0,
      sharesCount: 0,
      isLiked: true,
      createdAt: DateTime.now(),
    );

    ref.read(communityProvider.notifier).addUserPost(post);

    if (!mounted) return;
    setState(() => _isSharing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity shared to Community Feed! 🌿'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );

    widget.onDone();
  }

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

  @override
  Widget build(BuildContext context) {
    final distanceKm = widget.record.distanceMeters / 1000;
    final pathPoints = widget.record.path
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Summary'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // 1. Map Route Review Card
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: pathPoints.isNotEmpty
                      ? pathPoints.first
                      : (widget.record.destination != null
                          ? LatLng(
                              widget.record.destination!.latitude,
                              widget.record.destination!.longitude,
                            )
                          : const LatLng(6.95, 126.21)),
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
                    polylineId: const PolylineId('summary-glow'),
                    points: pathPoints,
                    color: AppColors.streakOrange.withValues(alpha: 0.3),
                    width: 8,
                    jointType: JointType.round,
                  ),
                  Polyline(
                    polylineId: const PolylineId('summary-core'),
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

          // 2. Editable Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.edit_note, color: AppColors.primaryGreen),
                hintText: 'Name your activity...',
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.forestDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Performance Analytics Grid
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
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestDark,
                  ),
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
                        label: 'Total Time',
                        value: _formatDuration(widget.record.duration),
                        icon: Icons.schedule,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Kilometer Splits Breakdown
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kilometer Splits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestDark,
                      ),
                    ),
                    Text(
                      '${widget.record.splits.length} laps',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SplitsChart(splits: widget.record.splits),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. EcoWell Nature & Wellness Check-in
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Nature & Wellness Reflection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quiet Score Star Rating
                const Text(
                  'Route Serenity (Quiet Score):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setState(() => _quietScore = i),
                        icon: Icon(
                          i <= _quietScore ? Icons.star : Icons.star_border,
                          color: AppColors.amberRating,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$_quietScore / 5',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mood / Mindful feeling tag
                const Text(
                  'How do you feel after this walk?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _moodOptions.map((mood) {
                    final selected = _selectedMood == mood;
                    return ChoiceChip(
                      label: Text(mood),
                      selected: selected,
                      selectedColor: AppColors.mintLight,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.forestDark
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryGreen
                            : AppColors.cardBorder,
                      ),
                      onSelected: (_) => setState(() => _selectedMood = mood),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Notes input
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add mindfulness notes or memories...',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. Action CTAs (Save & Share)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Save Activity',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSharing ? null : _shareToCommunity,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined, size: 20),
              label: const Text('Share to EcoWell Community'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forestDark,
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
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