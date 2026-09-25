import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../models/geo_fence.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/geofence_provider.dart';

/// Live geofence monitor readout.
///
/// Shows whether monitoring is running, any permission/location-service
/// failure, and either "Inside {place}" or the nearest fence + distance, so
/// silent detection failures become visible on the phone itself.
///
/// Tapping the chip opens a sheet listing every geofenced place with its live
/// distance and fence shape. Each entry can "Simulate" entering that place by
/// feeding its anchor through the same detection path as a real GPS fix, so
/// every arrival/departure flow can be verified without walking.
class GeofenceStatusChip extends ConsumerStatefulWidget {
  const GeofenceStatusChip({super.key});

  static const ({double latitude, double longitude}) outsidePoint = (
    latitude: 6.9500,
    longitude: 126.2157, // Mati City center, far from every fence
  );

  @override
  ConsumerState<GeofenceStatusChip> createState() =>
      _GeofenceStatusChipState();
}

class _GeofenceStatusChipState extends ConsumerState<GeofenceStatusChip> {
  @override
  Widget build(BuildContext context) {
    final geofence = ref.watch(geofenceProvider);
    final spaces = ref.watch(greenSpacesProvider);
    final (text, color) = _describe(geofence, spaces);

    return GestureDetector(
      onTap: _openPlacesSheet,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'View all geofenced places',
                child: Icon(Icons.tune_rounded, size: 13, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _describe(
    GeofenceState state,
    List<GreenSpace> spaces,
  ) {
    const waiting = Color(0xFFE5A13A);
    const insideColor = Color(0xFF48CAE4);
    const muted = Color(0xFF9EAAB3);
    const error = Color(0xFFE57373);

    if (!state.monitoring) {
      if (state.permissionDenied) {
        return ('Location permission denied - enable it in Settings', error);
      }
      if (state.serviceDisabled) {
        return ('Location service is off - turn on GPS', error);
      }
      return ('Geofence monitor inactive', muted);
    }

    final pos = state.position;
    if (pos == null) {
      return ('Waiting for GPS fix...', waiting);
    }

    final inside = state.insideSpace;
    if (inside != null) {
      return (
        'Inside ${inside.name}',
        insideColor,
      );
    }

    final nearest = _nearestSpace(pos, spaces);
    if (nearest == null) {
      return ('No geofenced places found', muted);
    }
    return (
      'Outside - nearest ${nearest.space.name} '
      '(${formatGeoDistance(nearest.meters)})',
      insideColor,
    );
  }

  ({GreenSpace space, double meters})? _nearestSpace(
    Position position,
    List<GreenSpace> spaces,
  ) {
    GreenSpace? nearest;
    var minMeters = double.infinity;
    for (final space in spaces) {
      final distance = distanceMeters(
        position.latitude,
        position.longitude,
        space.latitude,
        space.longitude,
      );
      if (distance < minMeters) {
        minMeters = distance;
        nearest = space;
      }
    }
    if (nearest == null) return null;
    return (space: nearest, meters: minMeters);
  }

  Future<void> _openPlacesSheet() async {
    final spaces = ref.read(greenSpacesProvider);
    final position = ref.read(geofenceProvider).position;

    final entries = <({GreenSpace space, double? meters})>[
      for (final space in spaces)
        (
          space: space,
          meters: position == null
              ? null
              : distanceMeters(
                  position.latitude,
                  position.longitude,
                  space.latitude,
                  space.longitude,
                ),
        ),
    ]..sort((a, b) {
        final aM = a.meters;
        final bM = b.meters;
        if (aM == null && bM == null) return 0;
        if (aM == null) return 1;
        if (bM == null) return -1;
        return aM.compareTo(bM);
      });
    final nearestMeters = entries.firstOrNull?.meters;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geofenced Places',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: Color(0xFF132B20),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    position == null
                        ? 'Waiting for GPS to measure distances...'
                        : 'Nearest place listed first. Tap Simulate to test an entry.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _SimulateActionRow(
                    icon: Icons.open_in_full_rounded,
                    label: 'Move outside all fences',
                    detail: 'Exits the current fence (tests the post-check)',
                    onTap: () {
                      Navigator.pop(ctx);
                      ref
                          .read(geofenceProvider.notifier)
                          .debugInjectPosition(
                            latitude: GeofenceStatusChip.outsidePoint.latitude,
                            longitude: GeofenceStatusChip.outsidePoint.longitude,
                          );
                    },
                  ),
                  const Divider(height: 1),
                  for (final entry in entries)
                    _PlaceRow(
                      entry: entry,
                      isNearest:
                          entry.meters != null && entry.meters == nearestMeters,
                      onSimulate: () {
                        Navigator.pop(ctx);
                        ref
                            .read(geofenceProvider.notifier)
                            .debugInjectPosition(
                              latitude: entry.space.latitude,
                              longitude: entry.space.longitude,
                            );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SimulateActionRow extends StatelessWidget {
  const _SimulateActionRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: const Color(0x1F48CAE4),
        child: Icon(icon, size: 15, color: const Color(0xFF0A1927)),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: const Text('Simulate', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.entry,
    required this.isNearest,
    required this.onSimulate,
  });

  final ({GreenSpace space, double? meters}) entry;
  final bool isNearest;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    final accent = entry.space.fence is PolygonFence
        ? Icons.change_history_rounded
        : Icons.circle;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isNearest
            ? const Color(0xFF48CAE4)
            : const Color(0x3390EEB0),
        child: Icon(
          accent,
          size: 15,
          color: isNearest ? const Color(0xFF0A1927) : const Color(0xFF1B7A3D),
        ),
      ),
      title: Text(
        entry.space.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.space.category} · ${entry.space.fenceLabel}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.meters == null
                    ? '--'
                    : formatGeoDistance(entry.meters!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isNearest
                      ? const Color(0xFF48CAE4)
                      : AppColors.textPrimary,
                ),
              ),
              if (isNearest)
                const Text(
                  'NEAREST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF48CAE4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSimulate,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Simulate', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}