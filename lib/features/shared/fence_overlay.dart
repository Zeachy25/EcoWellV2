import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/geo_fence.dart';
import '../../models/green_space.dart';

/// Shared Google Maps overlay builders for [GeoFence] rendering.
///
/// Keeps circle/polygon fence visuals and the closed-polygon vertex handling
/// identical across the live navigation, walk recorder, and explore maps.
class FenceOverlay {
  const FenceOverlay._();

  static const Color defaultFill = Color(0x1F1B7A3D);
  static const Color defaultStroke = AppColors.primaryGreen;

  /// Returns the circle overlay for a circular fence, or `null` for other
  /// fence types.
  static Circle? circleFor(
    GreenSpace space, {
    String id = 'destination-zone',
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
    VoidCallback? onTap,
    bool consumeTapEvents = false,
  }) {
    final fence = space.fence;
    if (fence is! CircleFence) return null;
    return Circle(
      circleId: CircleId(id),
      center: LatLng(space.latitude, space.longitude),
      radius: fence.radiusMeters,
      fillColor: fillColor ?? defaultFill,
      strokeColor: strokeColor ?? defaultStroke,
      strokeWidth: strokeWidth,
      consumeTapEvents: consumeTapEvents,
      onTap: onTap,
    );
  }

  /// Returns the polygon overlay for a polygon fence, or `null` for other
  /// fence types. The ring is explicitly closed for Google Maps rendering.
  static Polygon? polygonFor(
    GreenSpace space, {
    String id = 'destination-zone',
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
    VoidCallback? onTap,
    bool consumeTapEvents = false,
  }) {
    final fence = space.fence;
    if (fence is! PolygonFence) return null;
    final vertices = fence.vertices
        .map((vertex) => LatLng(vertex.latitude, vertex.longitude))
        .toList();
    if (vertices.isEmpty) return null;
    vertices.add(vertices.first);
    return Polygon(
      polygonId: PolygonId(id),
      points: vertices,
      fillColor: fillColor ?? defaultFill,
      strokeColor: strokeColor ?? defaultStroke,
      strokeWidth: strokeWidth,
      consumeTapEvents: consumeTapEvents,
      onTap: onTap,
    );
  }
}
