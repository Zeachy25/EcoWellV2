class PlaceReview {
  final String spaceId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime date;
  final bool isUser;

  const PlaceReview({
    this.spaceId = '',
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.isUser = false,
  });

  Map<String, dynamic> toJson() => {
        'spaceId': spaceId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
        'isUser': isUser,
      };

  factory PlaceReview.fromJson(Map<String, dynamic> json) => PlaceReview(
        spaceId: json['spaceId'] as String? ?? '',
        reviewerName: json['reviewerName'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        isUser: json['isUser'] as bool? ?? false,
      );
}