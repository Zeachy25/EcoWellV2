import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place_review.dart';
import 'app_providers.dart';

class ReviewsController extends Notifier<Map<String, List<PlaceReview>>> {
  @override
  Map<String, List<PlaceReview>> build() {
    final userReviews = ref.watch(localStoreProvider).getUserReviews();
    final bySpace = <String, List<PlaceReview>>{};
    for (final review in userReviews) {
      bySpace.putIfAbsent(review.spaceId, () => []).add(review);
    }
    return bySpace;
  }

  Future<void> addReview(PlaceReview review) async {
    await ref.read(localStoreProvider).addUserReview(review);
    state = {
      ...state,
      review.spaceId: [...(state[review.spaceId] ?? const []), review],
    };
  }
}

final reviewsProvider =
    NotifierProvider<ReviewsController, Map<String, List<PlaceReview>>>(
  ReviewsController.new,
);