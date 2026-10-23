import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/venue_model.dart';
import '../models/booking_model.dart';

class VenueRepository {
  final ApiClient _client = ApiClient();

  Future<List<SportCategoryModel>> getSports() async {
    try {
      final res = await _client.get(ApiConstants.sports, requiresAuth: false);
      if (res is List) {
        return res
            .map((e) => SportCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback Mock Sports
    return [
      SportCategoryModel(id: 1, name: 'Cầu lông', iconUrl: '🏸'),
      SportCategoryModel(id: 2, name: 'Pickleball', iconUrl: '🏓'),
      SportCategoryModel(id: 3, name: 'Bóng đá mini', iconUrl: '⚽'),
      SportCategoryModel(id: 4, name: 'Bóng rổ', iconUrl: '🏀'),
    ];
  }

  Future<List<VenueItemModel>> getVenues({
    int? sportId,
    String? search,
    double? userLat,
    double? userLng,
    double? radiusKm,
  }) async {
    final queryParams = <String, String>{};
    if (sportId != null && sportId > 0) queryParams['sportId'] = sportId.toString();
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
    if (userLat != null) queryParams['userLat'] = userLat.toString();
    if (userLng != null) queryParams['userLng'] = userLng.toString();
    if (radiusKm != null) queryParams['radiusKm'] = radiusKm.toString();

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final endpoint = queryString.isEmpty ? ApiConstants.venues : '${ApiConstants.venues}?$queryString';

    try {
      final res = await _client.get(endpoint, requiresAuth: false);
      if (res is List) {
        return res
            .map((e) => VenueItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback Mock 5 HCMC Venues
    return _getMockVenues(
      sportId: sportId,
      search: search,
      userLat: userLat,
      userLng: userLng,
      radiusKm: radiusKm,
    );
  }

  Future<VenueItemModel> getVenueDetail(int id) async {
    try {
      final res = await _client.get('/api/venues/$id', requiresAuth: false);
      if (res is Map<String, dynamic>) {
        return VenueItemModel.fromJson(res);
      }
    } catch (_) {}

    final all = _getMockVenues();
    return all.firstWhere((v) => v.id == id, orElse: () => all.first);
  }

  List<VenueItemModel> _getMockVenues({
    int? sportId,
    String? search,
    double? userLat,
    double? userLng,
    double? radiusKm,
  }) {
    final mockList = [
      VenueItemModel(
        id: 1,
        sportId: 1,
        sportName: 'Cầu lông',
        name: 'CLB Cầu Lông Kỳ Hòa',
        address: 'Số 238 đường 3/2, Phường 12',
        district: 'Quận 10',
        latitude: 10.7725,
        longitude: 106.6710,
        hotline: '0903123456',
        imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
        basePrice: 100000,
        peakPrice: 140000,
        rating: 4.9,
        amenities: 'Bãi đỗ ô tô, Căn tin, Phòng tắm nóng lạnh, Cho thuê vợt cao cấp, Wifi tốc độ cao',
        description: 'Cụm 8 sân thảm tiêu chuẩn Yonex, trần cao 11m thoáng mát, đèn led chống chói chuyên dụng.',
        distanceKm: 9.8,
        galleryImages: [
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200',
          'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200',
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200',
        ],
        subVenues: [
          SubVenueModel(id: 1, name: 'Sân Thảm 1'),
          SubVenueModel(id: 2, name: 'Sân Thảm 2'),
          SubVenueModel(id: 3, name: 'Sân Thảm 3'),
        ],
      ),
      VenueItemModel(
        id: 2,
        sportId: 3,
        sportName: 'Bóng đá mini',
        name: 'Sân Bóng Đá Mini Chảo Lửa',
        address: 'Số 30 Phan Thúc Duyện, Phường 4',
        district: 'Tân Bình',
        latitude: 10.8033,
        longitude: 106.6575,
        hotline: '0918765432',
        imageUrl: 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
        basePrice: 350000,
        peakPrice: 650000,
        rating: 4.8,
        amenities: 'Đèn chiếu sáng ban đêm, Trọng tài, Căn tin, Giữ xe miễn phí, Khán đài cổ vũ',
        description: 'Tổ hợp 6 sân cỏ nhân tạo đạt chuẩn FIFA, hệ thống thoát nước chuẩn và đèn LED ban đêm rực rỡ.',
        distanceKm: 13.5,
        galleryImages: [
          'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200',
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200',
        ],
        subVenues: [
          SubVenueModel(id: 4, name: 'Sân Cỏ 7A'),
          SubVenueModel(id: 5, name: 'Sân Cỏ 7B'),
        ],
      ),
      VenueItemModel(
        id: 3,
        sportId: 2,
        sportName: 'Pickleball',
        name: 'CLB Pickleball D-Sports Thủ Đức',
        address: 'Số 18 đường Song Hành, An Phú',
        district: 'TP. Thủ Đức',
        latitude: 10.8498,
        longitude: 106.7720,
        hotline: '0934567890',
        imageUrl: 'https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=800',
        basePrice: 120000,
        peakPrice: 180000,
        rating: 4.9,
        amenities: 'Phòng thay đồ, Huấn luyện viên, Cho thuê bóng & vợt, Ghế nghỉ ngơi, Nước uống miễn phí',
        description: 'Sân Pickleball mặt sân cao cấp USAPA, mái che thoáng mát, trang thiết bị hiện đại bậc nhất khu Đông.',
        distanceKm: 0.5,
        galleryImages: [
          'https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=1200',
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200',
        ],
        subVenues: [
          SubVenueModel(id: 6, name: 'Sân P1'),
          SubVenueModel(id: 7, name: 'Sân P2'),
        ],
      ),
      VenueItemModel(
        id: 4,
        sportId: 4,
        sportName: 'Bóng rổ',
        name: 'Sân Bóng Rổ TT TDTT Hồ Xuân Hương',
        address: 'Số 2 Hồ Xuân Hương, Phường 6',
        district: 'Quận 3',
        latitude: 10.7742,
        longitude: 106.6892,
        hotline: '0283930403',
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
        basePrice: 200000,
        peakPrice: 350000,
        rating: 4.7,
        amenities: 'Sàn gỗ FIBA, Máy lạnh, Phòng tắm, Căn tin dinh dưỡng, Bãi đỗ xe rộng rãi',
        description: 'Sân bóng rổ sàn gỗ thi đấu trong nhà chuẩn FIBA, bảng rổ kính cường lực và điều hòa nhiệt độ.',
        distanceKm: 10.2,
        galleryImages: [
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200',
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200',
        ],
        subVenues: [
          SubVenueModel(id: 8, name: 'Sân Trong Nhà'),
          SubVenueModel(id: 9, name: 'Sân Ngoài Trời'),
        ],
      ),
      VenueItemModel(
        id: 5,
        sportId: 1,
        sportName: 'Cầu lông',
        name: 'Cụm Sân Thể Thao Celadon Tân Phú',
        address: 'Số 2 đường Bờ Bao Tân Thắng, Sơn Kỳ',
        district: 'Tân Phú',
        latitude: 10.8018,
        longitude: 106.6162,
        hotline: '0908889999',
        imageUrl: 'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=800',
        basePrice: 110000,
        peakPrice: 150000,
        rating: 4.8,
        amenities: 'Công viên xanh, Phòng thay đồ cao cấp, Khu hồi phục cơ, Căn tin, Cho thuê dụng cụ',
        description: 'Khu liên hợp thể thao xanh với 10 sân cầu lông thảm PVC, không gian rộng rãi trong lòng đại đô thị Celadon.',
        distanceKm: 18.2,
        galleryImages: [
          'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200',
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200',
        ],
        subVenues: [
          SubVenueModel(id: 10, name: 'Sân Thảm 1'),
          SubVenueModel(id: 11, name: 'Sân Thảm 2'),
        ],
      ),
    ];

    var result = mockList.where((v) {
      if (sportId != null && sportId > 0 && v.sportId != sportId) return false;
      if (search != null && search.trim().isNotEmpty) {
        final kw = search.trim().toLowerCase();
        if (!v.name.toLowerCase().containsOrMatches(kw) &&
            !v.district.toLowerCase().containsOrMatches(kw) &&
            !v.address.toLowerCase().containsOrMatches(kw)) {
          return false;
        }
      }
      if (radiusKm != null && v.distanceKm != null && v.distanceKm! > radiusKm) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    return result;
  }
}

extension on String {
  bool containsOrMatches(String kw) => toLowerCase().contains(kw.toLowerCase());
}
