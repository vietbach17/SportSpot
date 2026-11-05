import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/venue_review_sheet.dart';
import '../../widgets/venue_image_carousel.dart';
import '../../data/models/venue_model.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/maps_launcher.dart';
import '../../data/sportspot_models.dart';
import '../booking/court_slots_screen.dart';
import '../../widgets/mini_pitch_map.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/brand_header.dart';

class VenueDetailScreen extends StatefulWidget {
  final dynamic venue;
  final IReviewRepository? reviewRepository;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.reviewRepository,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  String selectedSport = 'Cầu lông';
  late final IReviewRepository _reviewRepo =
      widget.reviewRepository ?? ApiReviewRepository();
  VenueReviewSummaryModel? _reviewSummary;
  bool _isLoadingReviews = false;
  bool _reviewsFailed = false;
  final IFavoriteRepository _favoriteRepo = ApiFavoriteRepository();
  bool _isFavorite = false;
  StreamSubscription<void>? _favSub;

  void _checkFavorite() async {
    try {
      final favs = await _favoriteRepo.getFavoriteVenueIds();
      if (mounted) setState(() => _isFavorite = favs.contains(_venueId));
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    await _favoriteRepo.toggleFavorite(_venueId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next ? 'Đã lưu sân vào danh sách yêu thích' : 'Đã bỏ yêu thích sân',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkFavorite();
    _favSub = _favoriteRepo.onFavoritesChanged.listen((_) {
      if (mounted) _checkFavorite();
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsFailed = false;
    });
    try {
      final summary = await _reviewRepo.getVenueReviews(_venueId);
      if (mounted) {
        setState(() {
          _reviewSummary = summary;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoadingReviews = false;
          _reviewsFailed = true;
        });
    }
  }

  int get _venueId {
    if (widget.venue is SportSpotVenue) {
      final s = widget.venue as SportSpotVenue;
      final parsed = int.tryParse(s.id);
      if (parsed != null) return parsed;
      if (s.id.contains('cau-giay') || s.name.toLowerCase().contains('cầu giấy')) return 1;
      if (s.id.contains('westlake') || s.id.contains('chao-lua') || s.name.toLowerCase().contains('chảo lửa')) return 2;
      if (s.id.contains('thao-dien') || s.id.contains('dsports') || s.name.toLowerCase().contains('pickleball')) return 3;
      if (s.id.contains('phu-my-hung') || s.id.contains('xuan-huong') || s.name.toLowerCase().contains('bóng rổ')) return 4;
      return 1;
    } else if (widget.venue is Map) {
      return int.tryParse(widget.venue['id']?.toString() ?? '1') ?? 1;
    } else {
      try {
        return int.tryParse(widget.venue.id.toString()) ?? 1;
      } catch (_) {
        return 1;
      }
    }
  }

  String get _venueName {
    try {
      return widget.venue.name?.toString() ?? 'CLB Thể Thao';
    } catch (_) {
      return 'CLB Thể Thao';
    }
  }

  String get _venueAddress {
    try {
      return widget.venue.address?.toString() ?? 'Quận Cầu Giấy, Hà Nội';
    } catch (_) {
      return 'Quận Cầu Giấy, Hà Nội';
    }
  }

  double? get _venueLatitude {
    try {
      if (widget.venue is VenueItemModel) {
        final lat = (widget.venue as VenueItemModel).latitude;
        return lat != 0.0 ? lat : null;
      }
      if (widget.venue is Map) {
        final lat = widget.venue['latitude'] ?? widget.venue['lat'];
        if (lat != null) {
          final val = (lat as num).toDouble();
          return val != 0.0 ? val : null;
        }
      }
      final dynamic v = widget.venue;
      if (v.latitude != null) {
        final val = (v.latitude as num).toDouble();
        return val != 0.0 ? val : null;
      }
    } catch (_) {}
    return null;
  }

  double? get _venueLongitude {
    try {
      if (widget.venue is VenueItemModel) {
        final lng = (widget.venue as VenueItemModel).longitude;
        return lng != 0.0 ? lng : null;
      }
      if (widget.venue is Map) {
        final lng = widget.venue['longitude'] ?? widget.venue['lng'];
        if (lng != null) {
          final val = (lng as num).toDouble();
          return val != 0.0 ? val : null;
        }
      }
      final dynamic v = widget.venue;
      if (v.longitude != null) {
        final val = (v.longitude as num).toDouble();
        return val != 0.0 ? val : null;
      }
    } catch (_) {}
    return null;
  }


  String get _venueDistance {
    try {
      if (widget.venue.distance != null)
        return widget.venue.distance.toString();
      if (widget.venue.distanceKm != null)
        return '${widget.venue.distanceKm} km';
    } catch (_) {}
    return '1.8 km';
  }

  String get _hotline {
    try {
      return widget.venue.hotline?.toString() ?? '0903123456';
    } catch (_) {
      return '0903123456';
    }
  }

  double get _rating {
    if (_reviewSummary != null) return _reviewSummary!.averageRating;
    try {
      if (widget.venue.rating != null) {
        return (widget.venue.rating as num).toDouble();
      }
    } catch (_) {}
    return 4.9;
  }

  String get _venueImage {
    try {
      if (widget.venue is SportSpotVenue) {
        final img = (widget.venue as SportSpotVenue).image;
        if (img.isNotEmpty) return img;
      }
      if (widget.venue.image != null &&
          widget.venue.image.toString().isNotEmpty) {
        return widget.venue.image.toString();
      }
      if (widget.venue.imageUrl != null &&
          widget.venue.imageUrl.toString().isNotEmpty) {
        return widget.venue.imageUrl.toString();
      }
    } catch (_) {}
    return 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200';
  }

  int get _basePrice {
    try {
      if (widget.venue.basePrice != null)
        return (widget.venue.basePrice as num).toInt();
      if (widget.venue.priceFrom != null)
        return (widget.venue.priceFrom as num).toInt();
    } catch (_) {}
    return 90000;
  }

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E313A)
        : const Color(0xFFE5E7EB);
    final textColor = isDark
        ? const Color(0xFFF6F6F3)
        : const Color(0xFF111315);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: SportSpotUnifiedHeader(
        screenName: 'Chi Tiết Sân Thi Đấu',
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : textColor,
            ),
            tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Lưu vào yêu thích',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: textColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép liên kết sân thi đấu! 📋'),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        isDark,
        cardColor,
        borderColor,
        textColor,
        mutedColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image with Athletic Vignette
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // 2. Title, Rating & Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _venueName,
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: mutedColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$_venueAddress • $_venueDistance',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Quick Actions: Hotline & Directions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hotline: $_hotline')),
                      );
                    },
                    icon: const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    label: const Text(
                      'Hotline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      MapsLauncher.openDirections(
                        latitude: _venueLatitude,
                        longitude: _venueLongitude,
                        address: _venueAddress,
                      );
                    },
                    icon: const Icon(
                      Icons.directions_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    label: const Text(
                      'Chỉ đường',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Athletic Court Specs Strip
            _buildCourtSpecsGrid(cardColor, borderColor, textColor, mutedColor),
            const SizedBox(height: 20),

            // 5. Mini Pitch Map
            MiniPitchMap(
              sportType: selectedSport,
              onCourtSelected: (court) {
                // Interactive court selection
              },
            ),
            const SizedBox(height: 20),

            // 6. Booking Flow Entry Invitation Card
            _buildBookingInvitation(
              cardColor,
              borderColor,
              textColor,
              mutedColor,
            ),
            const SizedBox(height: 20),

            // 6. Amenities
            Text(
              'TIỆN ÍCH KHU THI ĐẤU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: mutedColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildAmenitiesWrap(cardColor, borderColor, textColor),
            const SizedBox(height: 24),
            _buildReviewsSection(cardColor, borderColor, textColor, mutedColor),
          ],
        ),
      ),
    );
  }

  String get _openUntil {
    try {
      if (widget.venue is SportSpotVenue)
        return (widget.venue as SportSpotVenue).openUntil;
      if (widget.venue.openUntil != null)
        return widget.venue.openUntil.toString();
    } catch (_) {}
    return '23:00';
  }

  List<String> get _venueImages {
    List<String> list = [];
    try {
      if (widget.venue is SportSpotVenue) {
        final v = widget.venue as SportSpotVenue;
        if (v.images.isNotEmpty)
          list.addAll(v.images);
        else if (v.image.isNotEmpty)
          list.add(v.image);
      } else if (widget.venue is VenueItemModel) {
        final v = widget.venue as VenueItemModel;
        if (v.galleryImages.isNotEmpty)
          list.addAll(v.galleryImages);
        else if (v.imageUrl != null && v.imageUrl!.isNotEmpty)
          list.add(v.imageUrl!);
      } else if (widget.venue is Map) {
        final g = widget.venue['galleryImages'] ?? widget.venue['images'];
        if (g is List && g.isNotEmpty) {
          list.addAll(g.map((e) => e.toString()));
        } else if (widget.venue['image'] != null &&
            widget.venue['image'].toString().isNotEmpty) {
          list.add(widget.venue['image'].toString());
        } else if (widget.venue['imageUrl'] != null &&
            widget.venue['imageUrl'].toString().isNotEmpty) {
          list.add(widget.venue['imageUrl'].toString());
        }
      } else {
        final dynamic v = widget.venue;
        try {
          if (v.galleryImages != null && (v.galleryImages as List).isNotEmpty) {
            list.addAll((v.galleryImages as List).map((e) => e.toString()));
          } else if (v.images != null && (v.images as List).isNotEmpty) {
            list.addAll((v.images as List).map((e) => e.toString()));
          } else if (v.imageUrl != null && v.imageUrl.toString().isNotEmpty) {
            list.add(v.imageUrl.toString());
          } else if (v.image != null && v.image.toString().isNotEmpty) {
            list.add(v.image.toString());
          }
        } catch (_) {}
      }
    } catch (_) {}

    list = list.where((s) => s.trim().isNotEmpty).toList();
    if (list.length >= 2) return list;

    final base = list.isNotEmpty ? list.first : _venueImage;
    return [
      base,
      'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80',
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200&q=80',
    ];
  }

  Widget _buildHeroBanner() {
    return VenueImageCarousel(
      images: _venueImages,
      height: 220,
      openUntil: _openUntil,
      isVerified: true,
    );
  }

  Widget _buildCourtSpecsGrid(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THÔNG SỐ KỸ THUẬT SÂN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: mutedColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _specItem(
                'MẶT SÂN',
                'Thảm cao cấp 5mm',
                Icons.layers_outlined,
                textColor,
                mutedColor,
              ),
              _specItem(
                'QUY MÔ',
                '6 Sân thi đấu',
                Icons.grid_view_rounded,
                textColor,
                mutedColor,
              ),
              _specItem(
                'ÁNH SÁNG',
                'LED 500 Lux',
                Icons.lightbulb_outline_rounded,
                textColor,
                mutedColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specItem(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color mutedColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInvitation(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LỊCH TRỐNG THỜI GIAN THỰC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF38BDF8),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Đặt Lịch & Chọn Khung Giờ Thi Đấu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn sân đấu yêu thích, xem khung giờ trống trực tiếp trong 7 ngày và đặt cọc online giữ chỗ tức thì.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCourtSlots,
              icon: const Icon(Icons.calendar_month_rounded, size: 17),
              label: const Text(
                'Xem Khung Giờ & Đặt Ngay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111315),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesWrap(
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    final items = [
      {'label': 'Bãi đỗ ô tô & xe máy', 'icon': Icons.local_parking_rounded},
      {'label': 'Căn tin nước giải khát', 'icon': Icons.local_drink_rounded},
      {'label': 'Phòng thay đồ & tắm nóng', 'icon': Icons.shower_rounded},
      {'label': 'Cho thuê vợt & bóng', 'icon': Icons.sports_tennis_rounded},
      {'label': 'Wi-Fi tốc độ cao', 'icon': Icons.wifi_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['icon'] as IconData,
                size: 15,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickyBottomBar(
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GIÁ NIÊM YẾT TỪ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatVnd(_basePrice)} / giờ',
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF111315),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            AppPressable(
              onTap: _navigateToCourtSlots,
              child: ElevatedButton(
                onPressed: _navigateToCourtSlots,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111315),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Đặt Sân Ngay',
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCourtSlots() async {
    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {}
    if (auth != null && !auth.isAuthenticated) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khách vãng lai chỉ được tham gia ghép trận có sẵn. Vui lòng đăng nhập để đặt sân!'),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || !auth.isAuthenticated) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourtSlotsScreen(venueId: _venueId)),
    );
  }

  Widget _buildReviewsSection(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    final summary = _reviewSummary;
    final totalReviews = summary?.totalReviews ?? 0;
    final avgRating = summary?.averageRating ?? _rating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ĐÁNH GIÁ & XẾP HẠNG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: mutedColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReviews nhận xét từ cộng đồng',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _openReviewBottomSheet,
              icon: const Icon(
                Icons.rate_review_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              label: const Text(
                'Viết đánh giá',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                backgroundColor: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Summary Rating Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating.floor()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: const Color(0xFFF59E0B),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews đánh giá',
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = summary?.ratingBreakdown[star] ?? 0;
                    final ratio = totalReviews > 0 ? count / totalReviews : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star★',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: TextStyle(fontSize: 11, color: mutedColor),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviewsFailed)
          TextButton.icon(
            onPressed: _loadReviews,
            icon: const Icon(Icons.refresh),
            label: const Text('Không tải được đánh giá. Nhấn để thử lại'),
          )
        else if (summary == null || summary.reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'Chưa có đánh giá nào. Hãy là người đầu tiên trải nghiệm và để lại nhận xét!',
              style: TextStyle(fontSize: 13, color: mutedColor),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...summary.reviews.map(
            (r) => _buildReviewCard(
              r,
              cardColor,
              borderColor,
              textColor,
              mutedColor,
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(
    ReviewModel r,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2563EB),
                backgroundImage:
                    (r.userAvatarUrl != null && r.userAvatarUrl!.isNotEmpty)
                    ? NetworkImage(r.userAvatarUrl!)
                    : null,
                child: (r.userAvatarUrl != null && r.userAvatarUrl!.isNotEmpty)
                    ? null
                    : Text(
                        r.userName.isNotEmpty
                            ? r.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < r.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 13,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.comment,
            style: TextStyle(fontSize: 13, color: textColor, height: 1.35),
          ),
        ],
      ),
    );
  }

  Future<void> _openReviewBottomSheet() async {
    final submitted = await VenueReviewSheet.show(
      context,
      venueId: _venueId,
      venueName: _venueName,
      repository: _reviewRepo,
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!')),
    );
    await _loadReviews();
  }
}
