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
  });

  double get quietScore {
    if (reviews.isNotEmpty) {
      final sum = reviews.fold(0.0, (acc, r) => acc + r.rating);
      return double.parse((sum / reviews.length).toStringAsFixed(1));
    }
    return (calmFactor.value + noiseLevel.value + crowdDensity.value) / 3;
  }
}