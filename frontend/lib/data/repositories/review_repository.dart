import '../../core/network/api_client.dart';
import '../models/review_model.dart';

abstract class IReviewRepository {
  Future<VenueReviewSummaryModel> getVenueReviews(int venueId);
  Future<ReviewModel> submitReview(int venueId, int rating, String comment);
}

class MockReviewRepository implements IReviewRepository {
  final Map<int, List<ReviewModel>> _reviewsByVenue = {
    1: [
      ReviewModel(
        id: 1,
        venueId: 1,
        userId: 1,
        userName: 'Nguyễn Văn Minh',
        userAvatarUrl: null,
        rating: 5,
        comment: 'Sân thảm tiêu chuẩn BWF cực êm, hệ thống đèn chống chói rất tốt. Đặt cọc qua app check-in QR siêu nhanh!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReviewModel(
        id: 2,
        venueId: 1,
        userId: 2,
        userName: 'Trần Thị Thu Trang',
        userAvatarUrl: null,
        rating: 5,
        comment: 'Cụm sân sạch sẽ, chỗ để xe ô tô rộng rãi. Căn tin có bán đủ nước bù điện giải.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ReviewModel(
        id: 3,
        venueId: 1,
        userId: 3,
        userName: 'Lê Hoàng Nam',
        userAvatarUrl: null,
        rating: 4,
        comment: 'Sân đẹp, mặt sân bám giày tốt. Giờ cao điểm hơi đông người một chút nhưng nhân viên điều phối rất ổn.',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ],
  };

  @override
  Future<VenueReviewSummaryModel> getVenueReviews(int venueId) async {
    
    final list = _reviewsByVenue[venueId] ?? _reviewsByVenue[1] ?? [];
    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in list) {
      breakdown[r.rating] = (breakdown[r.rating] ?? 0) + 1;
    }
    final avg = list.isNotEmpty
        ? list.map((r) => r.rating).reduce((a, b) => a + b) / list.length
        : 5.0;

    return VenueReviewSummaryModel(
      venueId: venueId,
      averageRating: double.parse(avg.toStringAsFixed(1)),
      totalReviews: list.length,
      ratingBreakdown: breakdown,
      reviews: List.from(list),
    );
  }

  @override
  Future<ReviewModel> submitReview(int venueId, int rating, String comment) async {
    
    final newReview = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      venueId: venueId,
      userId: 99,
      userName: 'Bạn (Người dùng hiện tại)',
      userAvatarUrl: null,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    if (!_reviewsByVenue.containsKey(venueId)) {
      _reviewsByVenue[venueId] = [];
    }
    _reviewsByVenue[venueId]!.insert(0, newReview);
    return newReview;
  }
}

class ApiReviewRepository implements IReviewRepository {
  final ApiClient _client;
  final MockReviewRepository _fallback = MockReviewRepository();

  ApiReviewRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<VenueReviewSummaryModel> getVenueReviews(int venueId) async {
    try {
      final response = await _client.get('/api/venues/$venueId/reviews', requiresAuth: false);
      if (response is Map<String, dynamic>) {
        return VenueReviewSummaryModel.fromJson(response);
      }
      return await _fallback.getVenueReviews(venueId);
    } catch (_) {
      return await _fallback.getVenueReviews(venueId);
    }
  }

  @override
  Future<ReviewModel> submitReview(int venueId, int rating, String comment) async {
    try {
      final response = await _client.post('/api/reviews', {
        'venueId': venueId,
        'rating': rating,
        'comment': comment,
      });
      if (response is Map<String, dynamic>) {
        return ReviewModel.fromJson(response);
      }
      return await _fallback.submitReview(venueId, rating, comment);
    } catch (_) {
      return await _fallback.submitReview(venueId, rating, comment);
    }
  }
}
