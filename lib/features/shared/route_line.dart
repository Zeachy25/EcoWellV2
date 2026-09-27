import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared styling for a planned route line on the map.
///
/// A real routed path and the recorded activity trail share one look, so a
/// route line reads the same before, during, and after an activity. A
/// straight-line fallback (used when routing is unavailable) keeps the same
/// color and width but is dashed, so the only difference users see is that the
/// path is not a real street route.
class RouteLine {
  const RouteLine._();

  /// Brand route blue, shared with the recorded activity trail.
  static const Color plannedColor = Color(0xFF4285F4);

  /// Route line width, matching the recorded activity trail.
  static const int plannedWidth = 5;

  /// Same blue at reduced opacity for the dashed straight-line fallback.
  static const Color fallbackColor = Color(0x8A4285F4);

  /// The fallback keeps the same width as a real route.
  static const int fallbackWidth = 5;

  /// Dash pattern used for the straight-line fallback.
  static final List<PatternItem> fallbackPattern = <PatternItem>[
    PatternItem.dash(16),
    PatternItem.gap(12),
  ];

  /// Whether [points] represents a real route rather than a fallback line.
  static bool isRealRoute(List<LatLng>? points) =>
      points != null && points.length >= 2;

  /// Builds the route polyline for [points].
  ///
  /// When [points] is null or too short the line is treated as a fallback and
  /// rendered dashed, provided [fallback] supplies at least two points.
  static Polyline? polyline({
    required String id,
    required List<LatLng>? points,
    List<LatLng> fallback = const [],
    int zIndex = 4,
    bool jointTypeRound = false,
  }) {
    final real = isRealRoute(points);
    final resolved = real ? points! : fallback;
    if (resolved.length < 2) return null;
    return Polyline(
      polylineId: PolylineId(id),
      points: resolved,
      color: real ? plannedColor : fallbackColor,
      width: plannedWidth,
      patterns: real ? const <PatternItem>[] : fallbackPattern,
      jointType: jointTypeRound ? JointType.round : JointType.bevel,
      zIndex: zIndex,
    );
  }
}
