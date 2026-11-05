import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sportspot_models.dart';
import '../../data/models/venue_model.dart';
import '../screens/booking/court_slots_screen.dart';
import '../screens/venues/venue_detail_screen.dart';
import 'venue_image_carousel.dart';

class VenueBookingModal extends StatelessWidget {
  final dynamic venue;

  const VenueBookingModal({
    super.key,
    required this.venue,
  });

  static Future<void> show(BuildContext context, {required dynamic venue}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VenueBookingModal(venue: venue),
    );
  }

  int get _venueId {
    if (venue is SportSpotVenue) {
      return int.tryParse((venue as SportSpotVenue).id) ?? 1;
    } else if (venue is VenueItemModel) {
      return (venue as VenueItemModel).id;
    } else if (venue is Map) {
      return int.tryParse(venue['id']?.toString() ?? '1') ?? 1;
    }
    return 1;
  }

  String get _name {
    try {
      return venue.name?.toString() ?? 'Sân Thể Thao';
    } catch (_) {
      return 'Sân Thể Thao';
    }
  }

  String get _address {
    try {
      return venue.address?.toString() ?? 'Khu vực trung tâm';
    } catch (_) {
      return 'Khu vực trung tâm';
    }
  }

  String get _distance {
    try {
      if (venue is SportSpotVenue) return (venue as SportSpotVenue).distance;
      if (venue is VenueItemModel) return (venue as VenueItemModel).distance;
    } catch (_) {}
    return '1.5 km';
  }

  double get _rating {
    try {
      if (venue.rating != null) return (venue.rating as num).toDouble();
    } catch (_) {}
    return 4.9;
  }


  List<String> get _images {
    List<String> list = [];
    try {
      if (venue is SportSpotVenue) {
        final v = venue as SportSpotVenue;
        if (v.images.isNotEmpty) list.addAll(v.images);
        else if (v.image.isNotEmpty) list.add(v.image);
      } else if (venue is VenueItemModel) {
        final v = venue as VenueItemModel;
        if (v.galleryImages.isNotEmpty) list.addAll(v.galleryImages);
        else if (v.imageUrl != null && v.imageUrl!.isNotEmpty) list.add(v.imageUrl!);
      }
    } catch (_) {}

    list = list.where((s) => s.trim().isNotEmpty).toList();
    if (list.length >= 2) return list;

    final primary = list.isNotEmpty
        ? list.first
        : 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80';
    return [
      primary,
      'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80',
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Title & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thông Tin Đặt Sân',
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Image Carousel with swipe & pagination dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VenueImageCarousel(
                images: _images,
                height: 190,
                borderRadius: 14,
                openUntil: '23:00',
              ),
            ),
            const SizedBox(height: 14),

            // Venue info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _name,
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: mutedColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$_address • $_distance',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: borderColor),
                  const SizedBox(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VenueDetailScreen(venue: venue),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Xem Chi Tiết',
                            style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            AuthProvider? auth;
                            try {
                              auth = context.read<AuthProvider>();
                            } catch (_) {}
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            nav.pop();
                            if (auth != null && !auth.isAuthenticated) {
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Khách vãng lai chỉ được tham gia ghép trận có sẵn. Vui lòng đăng nhập để đặt sân!'),
                                ),
                              );
                              await nav.push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                              if (!auth.isAuthenticated) return;
                            }
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => CourtSlotsScreen(venueId: _venueId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111315),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Đặt Sân Ngay',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
