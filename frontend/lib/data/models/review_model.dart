class ReviewModel {
  final int id;
  final int venueId;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int? ?? 0,
      venueId: json['venueId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? 'Khách hàng',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venueId': venueId,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

class VenueReviewSummaryModel {
  final int venueId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;
  final List<ReviewModel> reviews;

  const VenueReviewSummaryModel({
    required this.venueId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.reviews,
  });

  factory VenueReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownRaw = json['ratingBreakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <int, int>{};
    for (int star = 1; star <= 5; star++) {
      breakdown[star] = (breakdownRaw[star.toString()] as num?)?.toInt() ?? 0;
    }

    final reviewsRaw = json['reviews'] as List<dynamic>? ?? [];
    final reviewList = reviewsRaw
        .map((r) => ReviewModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    return VenueReviewSummaryModel(
      venueId: json['venueId'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['totalReviews'] as int? ?? reviewList.length,
      ratingBreakdown: breakdown,
      reviews: reviewList,
    );
  }
}
