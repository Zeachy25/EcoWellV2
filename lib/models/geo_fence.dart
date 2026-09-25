import '../core/utils/geo.dart';

/// A geographic coordinate pair used as a geofence polygon vertex.
class GeoCoord {
  final double latitude;
  final double longitude;

  const GeoCoord(this.latitude, this.longitude);
}

/// Shape of a geofenced area around a [GreenSpace].
///
/// A place can either use a circular [CircleFence] (center + radius, the
/// default) or an arbitrary [PolygonFence] (list of corners, e.g. a trapezoid
/// hugging a beach shore). Enter/exit detection flows through [contains].
sealed class GeoFence {
  const GeoFence();

  /// Whether [latitude]/[longitude] falls inside this geofenced area.
  bool contains(double latitude, double longitude);

  /// Short human-readable shape description for map snippets and chips.
  String get label;
}

/// A circular geofence - a center point plus a radius in meters.
class CircleFence extends GeoFence {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const CircleFence({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  @override
  bool contains(double latitude, double longitude) =>
      distanceMeters(this.latitude, this.longitude, latitude, longitude) <=
      radiusMeters;

  @override
  String get label => '${radiusMeters.round()} m radius';
}

/// An arbitrary polygon geofence defined by its corner coordinates.
///
/// The shape is treated as closed (the last corner connects back to the
/// first), so 4 corners form a trapezoid/quadrilateral and 3 a triangle.
class PolygonFence extends GeoFence {
  final List<GeoCoord> vertices;

  const PolygonFence(this.vertices);

  /// Ray-casting point-in-polygon test (works for concave shapes too).
  @override
  bool contains(double latitude, double longitude) {
    var inside = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final vi = vertices[i];
      final vj = vertices[j];
      final intersects =
          (vi.latitude > latitude) != (vj.latitude > latitude) &&
          (longitude <
              (vj.longitude - vi.longitude) *
                      (latitude - vi.latitude) /
                      (vj.latitude - vi.latitude) +
                  vi.longitude);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  @override
  String get label => 'polygon (${vertices.length} pts)';
}