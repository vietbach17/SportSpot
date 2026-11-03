import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/venue_model.dart';
import '../../providers/venue_provider.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';
import '../../widgets/confirm_action_sheet.dart';
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final bgColor = isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top User Profile & Quick Controls Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00A859),
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 17,
                              backgroundImage: NetworkImage(SportSpotMockData.userNam),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                          letterSpacing: -0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.verified, size: 14, color: Color(0xFF00A859)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        'Cầu Giấy, Hà Nội',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
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
                  const SizedBox(width: 10),

                  // Right Utility Controls: Radius + Notification
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _cycleRadius,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.radar_rounded, size: 16, color: Color(0xFF00A859)),
                            const SizedBox(width: 5),
                            Text(
                              '$radiusKm km',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, size: 19),
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A859),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sân, cụm sân hoặc quận...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
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
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Tactical Shortcuts
              Row(
                children: [
                  _buildQuickAction('Đăng ký sân', Icons.add_business_rounded, const Color(0xFF111315), () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await SportSpotConfirmSheet.show(
                      context,
                      title: 'Đăng Ký Cụm Sân Mới',
                      message: 'Bạn muốn trở thành đối tác chủ sân trên hệ thống SportSpot? Đội ngũ quản trị sẽ liên hệ xác minh.',
                      confirmLabel: 'Mở mẫu đăng ký',
                      cancelLabel: 'Để sau',
                      icon: Icons.add_business_rounded,
                      actionType: ConfirmActionType.success,
                    );
                    if (!mounted) return;
                    if (confirmed == true) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mở mẫu đăng ký cụm sân mới'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }, isDark, borderColor, cardBg),
                  const SizedBox(width: 8),
                  _buildQuickAction('Tạo trận', Icons.group_add_rounded, const Color(0xFF00A859), () {
                    if (widget.onNavigateToMatches != null) {
                      widget.onNavigateToMatches!();
                    }
                  }, isDark, borderColor, cardBg),
                  const SizedBox(width: 8),
                  _buildQuickAction('Hỗ trợ', Icons.support_agent_rounded, const Color(0xFF6B7280), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hỗ trợ trực tuyến 24/7'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }, isDark, borderColor, cardBg),
                ],
              ),
              const SizedBox(height: 20),

              // Category Filter Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Bộ Môn Thể Thao',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Color(0xFF00A859),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF111315))
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : borderColor,
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat.contains('Badminton')
                                  ? Icons.sports_tennis_rounded
                                  : cat.contains('Football')
                                      ? Icons.sports_soccer_rounded
                                      : cat.contains('Basketball')
                                          ? Icons.sports_basketball_rounded
                                          : cat.contains('Pickleball')
                                              ? Icons.sports_baseball_rounded
                                              : Icons.tune_rounded,
                              size: 16,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF111315) : Colors.white)
                                  : const Color(0xFF00A859),
                            ),
                            const SizedBox(width: 7),
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
              const SizedBox(height: 20),

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
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111315),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 1.2),
                    image: const DecorationImage(
                      image: NetworkImage(SportSpotMockData.heroBanner),
                      fit: BoxFit.cover,
                      opacity: 0.72,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xD90D0E12),
                              Color(0xF50D0E12),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Text(
                                      "⚡ Chia tiền tức thì",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00C853), Color(0xFF00A859)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00A859).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "Tiết kiệm 30%",
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
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
                                        style: TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Đặt Sân Cùng Bạn Bè & Chia Tiền Tức Thì',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF111315), size: 19),
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
              const SizedBox(height: 24),

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
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  Text(
                                    'Sân Thể Thao Nổi Bật',
                                    style: TextStyle(
                                      fontFamily: AppTheme.headingFont,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFEBEBE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${displayVenues.length}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF111315),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (hasLiveApi ? const Color(0xFF00A859) : const Color(0xFFD9532F)).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: hasLiveApi ? const Color(0xFF00A859) : const Color(0xFFD9532F),
                                        width: 1,
                                      ),
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
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                            child: const Text(
                              'Làm mới',
                              style: TextStyle(
                                color: Color(0xFF00A859),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (venueProvider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF00A859)),
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
                  Expanded(
                    child: Text(
                      'Kèo Giao Lưu Gần Bạn',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onNavigateToMatches,
                    child: const Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: Color(0xFF00A859),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00A859), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(SportSpotMockData.coachMinh),
                      ),
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
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F3F5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Adv 4.0',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF00A859), fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Đôi nam nữ • 19:00 Tối nay',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.groups_rounded, size: 15, color: Color(0xFF00A859)),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '3/4 Người đã tham gia',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF00A859), fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: widget.onNavigateToMatches,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Vào kèo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
    Color borderColor,
    Color cardBg,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image with modern top radius
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Stack(
              children: [
                AspectRatio(
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
                // Modern top pill on image
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      venue.distance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                          fontFamily: AppTheme.headingFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111315),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFF00A859)),
                          const SizedBox(width: 3),
                          Text(
                            '${venue.rating}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00A859),
                            ),
                          ),
                          Text(
                            ' (${venue.reviewCount})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Location line
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${venue.address} • ${venue.distance}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Structural line divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
                const SizedBox(height: 14),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00A859),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Từ ${venue.priceFrom ~/ 1000}k/giờ',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: 15,
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đặt Sân Ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
