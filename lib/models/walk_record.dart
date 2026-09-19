import 'dart:math';

import 'package:flutter/material.dart';

import 'green_space.dart';

/// Geographic point with altitude and timestamp for GPS tracking.
class GeoPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    required this.timestamp,
  });
}

/// Activity types supported by the walk tracker.
enum WalkActivityType {
  walk,
  run,
  hike,
  trail,
}

extension WalkActivityTypeLabel on WalkActivityType {
  String get label => switch (this) {
        WalkActivityType.walk => 'Walk',
        WalkActivityType.run => 'Run',
        WalkActivityType.hike => 'Hike',
        WalkActivityType.trail => 'Trail',
      };

  IconData get icon => switch (this) {
        WalkActivityType.walk => Icons.directions_walk,
        WalkActivityType.run => Icons.directions_run,
        WalkActivityType.hike => Icons.terrain,
        WalkActivityType.trail => Icons.nature_people,
      };
}

/// Per-kilometer split data for pacing analytics.
class ActivitySplit {
  final int splitNumber;
  final Duration duration;
  final double distanceMeters;
  final int avgPaceSecondsPerKm;
  final double elevationGainMeters;

  const ActivitySplit({
    required this.splitNumber,
    required this.duration,
    required this.distanceMeters,
    required this.avgPaceSecondsPerKm,
    required this.elevationGainMeters,
  });
}

/// A complete GPS activity record with metrics, path, and splits.
class WalkRecord {
  final String id;
  final String userId;
  final GreenSpace? destination;
  final WalkActivityType activityType;
  final String title;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration movingDuration;
  final List<GeoPoint> path;
  final List<ActivitySplit> splits;
  final double elevationGainMeters;
  final int caloriesBurned;
  final bool arrived;
  final int? quietRating;
  final String? moodTag;
  final String? notes;

  const WalkRecord({
    required this.id,
    required this.userId,
    this.destination,
    required this.activityType,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.movingDuration,
    required this.path,
    this.splits = const [],
    this.elevationGainMeters = 0,
    this.caloriesBurned = 0,
    this.arrived = false,
    this.quietRating,
    this.moodTag,
    this.notes,
  });

  Duration get duration => endedAt.difference(startedAt);

  Duration get activeDuration => movingDuration;

  double get distanceMeters {
    double total = 0;
    for (var i = 1; i < path.length; i++) {
      total += _haversine(path[i - 1], path[i]);
    }
    return total;
  }

  int get avgPaceSecondsPerKm {
    final distKm = distanceMeters / 1000;
    if (distKm <= 0) return 0;
    return (movingDuration.inSeconds / distKm).round();
  }

  String get formattedAvgPace {
    final pace = avgPaceSecondsPerKm;
    if (pace <= 0) return '—';
    final m = pace ~/ 60;
    final s = (pace % 60).toString().padLeft(2, '0');
    return "$m'$s\" /km";
  }

  String get displayTitle {
    if (title.isNotEmpty) return title;
    final destName = destination?.name;
    final typeLabel = activityType.label;
    if (destName != null) return '$typeLabel at $destName';
    return '$typeLabel ${_fmtDate(startedAt)}';
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static double _haversine(GeoPoint a, GeoPoint b) {
    const R = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude) * cos(b.latitude) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * R * asin(sqrt(h));
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
}
