import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/venue_model.dart';
import '../../providers/venue_provider.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';
import '../venues/venue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMatches;

  const HomeScreen({
    super.key,
    this.onNavigateToMatches,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int radiusKm = 5;
  String selectedCategory = 'Badminton';
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'Tất cả',
    'Badminton',
    'Pickleball',
    'Mini Football',
    'Basketball',
    'Padel',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<VenueProvider>().onSearchChanged(_searchController.text);
  }

  int? _getSportId(String cat) {
    if (cat == 'Tất cả') return null;
    if (cat.contains('Badminton')) return 1;
    if (cat.contains('Pickleball')) return 2;
    if (cat.contains('Football')) return 3;
    if (cat.contains('Basketball')) return 4;
    return null;
  }

  void _cycleRadius() {
    setState(() {
      radiusKm = radiusKm == 5 ? 10 : radiusKm == 10 ? 15 : 5;
    });
    context.read<VenueProvider>().setRadius(radiusKm.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bán kính tìm kiếm: $radiusKm km xung quanh bạn'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0);
    final cardBg = isDark ? const Color(0xFF191A1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF6F6F3),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top User Profile & Quick Controls Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 17,
                            backgroundImage: NetworkImage(SportSpotMockData.userNam),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Nam Nguyen',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.verified, size: 14, color: Color(0xFF00A859)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        'Cầu Giấy, Hà Nội',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(width: 8),

                  // Right Utility Controls
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _cycleRadius,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore_outlined, size: 15, color: Color(0xFF111315)),
                              const SizedBox(width: 4),
                              Text(
                                '$radiusKm km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(
                                width: 0,
                                height: 0,
                                child: OverflowBox(
                                  maxWidth: 0,
                                  maxHeight: 0,
                                  child: Text('Bán kính quét khoảng cách'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sân, cụm sân hoặc quận...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFEBEBE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Quick Tactical Shortcuts
              Row(
                children: [
                  _buildQuickAction('Đăng ký sân', Icons.add_business_outlined, const Color(0xFF111315), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mở mẫu đăng ký cụm sân mới')),
                    );
                  }, isDark, borderColor, cardBg),
                  const SizedBox(width: 8),
                  _buildQuickAction('Tạo trận', Icons.group_add_outlined, const Color(0xFF00A859), () {
                    if (widget.onNavigateToMatches != null) {
                      widget.onNavigateToMatches!();
                    }
                  }, isDark, borderColor, cardBg),
                  const SizedBox(width: 8),
                  _buildQuickAction('Hỗ trợ', Icons.support_agent_outlined, const Color(0xFF6B7280), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hỗ trợ trực tuyến 24/7')),
                    );
                  }, isDark, borderColor, cardBg),
                ],
              ),
              const SizedBox(height: 18),

              // Category Filter Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Bộ Môn Thể Thao',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFF111315), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = cat);
                        context.read<VenueProvider>().selectSport(_getSportId(cat));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF111315))
                              : cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat.contains('Badminton')
                                  ? Icons.sports_tennis_rounded
                                  : cat.contains('Football')
                                      ? Icons.sports_soccer_rounded
                                      : Icons.sports_baseball_rounded,
                              size: 15,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF111315) : Colors.white)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? const Color(0xFF111315) : Colors.white)
                                    : (isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Hero Promotional Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailScreen(venue: SportSpotMockData.venues.first),
                    ),
                  );
                },
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111315),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                    image: const DecorationImage(
                      image: NetworkImage(SportSpotMockData.heroBanner),
                      fit: BoxFit.cover,
                      opacity: 0.75,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xEB111315)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111315),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "⚡ Chia tiền tức thì",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A859),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("Tiết kiệm 30%", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SÂN ĐẸP CUỐI TUẦN',
                                        style: TextStyle(color: Color(0xFF00A859), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Đặt Sân Cùng Bạn Bè & Chia Tiền Tức Thì',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF111315), size: 18),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Featured Venues Section
              Builder(
                builder: (context) {
                  final venueProvider = context.watch<VenueProvider>();
                  final bool hasLiveApi = venueProvider.venues.isNotEmpty;
                  final List<SportSpotVenue> displayVenues = hasLiveApi
                      ? venueProvider.venues.map((v) => v.toSportSpotVenue()).toList()
                      : SportSpotMockData.venues;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const Text(
                                    'Sân Thể Thao Nổi Bật',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFEBEBE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${displayVenues.length}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111315)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (hasLiveApi ? const Color(0xFF00A859) : const Color(0xFFD9532F)).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: hasLiveApi ? const Color(0xFF00A859) : const Color(0xFFD9532F)),
                                    ),
                                    child: Text(
                                      hasLiveApi ? 'LIVE API' : 'MÔ PHỎNG',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: hasLiveApi ? const Color(0xFF00A859) : const Color(0xFFD9532F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<VenueProvider>().refreshVenues(),
                            child: const Text('Làm mới', style: TextStyle(color: Color(0xFF111315), fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (venueProvider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        ...displayVenues.map((venue) => _buildVenueCard(context, venue, isDark, borderColor, cardBg)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Open Matches Nearby Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Kèo Giao Lưu Gần Bạn',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onNavigateToMatches,
                    child: const Text('Xem thêm', style: TextStyle(color: Color(0xFF111315), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(SportSpotMockData.coachMinh),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Coach Minh Le',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFEBEBE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Adv 4.0', style: TextStyle(fontSize: 9, color: Color(0xFF111315), fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Đôi nam nữ • 19:00 Tối nay',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Icon(Icons.groups_rounded, size: 14, color: Color(0xFF00A859)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '3/4 Người đã tham gia',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF00A859), fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.onNavigateToMatches,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      ),
                      child: const Text('Vào kèo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap, bool isDark, Color borderColor, Color cardBg) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, SportSpotVenue venue, bool isDark, Color borderColor, Color cardBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image with 9px top radius - no floating bubble badges
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                venue.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFEBEBE7),
                  child: Center(
                    child: Icon(Icons.sports_tennis_rounded, color: isDark ? Colors.white54 : const Color(0xFF111315), size: 36),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top line: Name + Rating badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111315),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFF00A859)),
                          const SizedBox(width: 3),
                          Text(
                            '${venue.rating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00A859),
                            ),
                          ),
                          Text(
                            ' (${venue.reviewCount})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Location line
                Row(
                  children: [
                    Icon(Icons.near_me_outlined, size: 13, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${venue.address} • ${venue.distance}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Structural line divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
                const SizedBox(height: 12),
                // Bottom row: Slots available & Price + CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A859),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${venue.slotsAvailableToday} khung giờ trống hôm nay',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00A859),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Từ ${venue.priceFrom ~/ 1000}k/giờ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF111315),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VenueDetailScreen(venue: venue),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Đặt Sân Ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
