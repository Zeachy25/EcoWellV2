import '../core/config/app_config.dart';
import 'geo_fence.dart';
import 'place_review.dart';

enum CrowdLevel { low, moderate, high }

extension CrowdLevelLabel on CrowdLevel {
  String get label => switch (this) {
    CrowdLevel.low => 'Low',
    CrowdLevel.moderate => 'Moderate',
    CrowdLevel.high => 'High',
  };

  int get value => switch (this) {
    CrowdLevel.low => 5,
    CrowdLevel.moderate => 3,
    CrowdLevel.high => 1,
  };
}

class GreenSpace {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final CrowdLevel noiseLevel;
  final CrowdLevel crowdDensity;
  final CrowdLevel calmFactor;
  final List<PlaceReview> reviews;
  final String? imageUrl;
  final String? destressTag;
  final double? distanceKm;
  final List<String> tags;

  /// The geofence size (meters) around this place. Enter/exit detection and
  /// the map circle use this radius. Defaults to 150m when not specified.
  /// Ignored when [polygonVertices] is set.
  final double radiusMeters;

  /// Optional polygon corners that shape this place's geofence. When set (3+
  /// corners), the geofence becomes a [PolygonFence] instead of a radius
  /// circle, so you can trace an exact boundary - e.g. a trapezoid following a
  /// beach shoreline. The shape is treated as closed (auto-connects last to
  /// first corner).
  final List<GeoCoord>? polygonVertices;

  const GreenSpace({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    this.noiseLevel = CrowdLevel.moderate,
    this.crowdDensity = CrowdLevel.moderate,
    this.calmFactor = CrowdLevel.moderate,
    this.reviews = const [],
    this.imageUrl,
    this.destressTag,
    this.distanceKm,
    this.tags = const [],
    this.radiusMeters = AppConfig.geofenceRadiusMeters,
    this.polygonVertices,
  });

  /// The geofence shape for this place - a radius circle by default, or the
  /// [PolygonFence] built from [polygonVertices] when 3+ corners are given.
  GeoFence get fence {
    final vertices = polygonVertices;
    if (vertices != null && vertices.length >= 3) {
      return PolygonFence(vertices);
    }
    return CircleFence(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  /// Short label describing this place's geofence shape.
  String get fenceLabel => fence.label;

  double get quietScore {
    if (reviews.isNotEmpty) {
      final sum = reviews.fold(0.0, (acc, r) => acc + r.rating);
      return double.parse((sum / reviews.length).toStringAsFixed(1));
    }
    return (calmFactor.value + noiseLevel.value + crowdDensity.value) / 3;
  }
}
