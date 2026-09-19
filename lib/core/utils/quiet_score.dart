import '../../models/green_space.dart';
import '../../models/place_review.dart';
import '../../models/visit.dart';

double quietScoreFor(GreenSpace space, List<Visit> visits) {
  final spaceVisits = visits
      .where((v) => v.greenSpaceId == space.id && v.quietRating > 0)
      .toList();
  if (spaceVisits.isEmpty) return space.quietScore;
  final userAvg =
      spaceVisits.fold<int>(0, (sum, v) => sum + v.quietRating) /
          spaceVisits.length;
  return (space.quietScore + userAvg) / 2;
}

double reviewRatingFor(
  GreenSpace space,
  List<PlaceReview> userReviews,
) {
  final all = [...space.reviews, ...userReviews];
  if (all.isEmpty) return 0;
  return all.fold<double>(0, (sum, r) => sum + r.rating) / all.length;
}

bool isHighlyRecommended(double quietScore) => quietScore >= 4.0;