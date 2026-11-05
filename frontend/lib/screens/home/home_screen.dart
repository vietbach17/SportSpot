import '../owner/venue_applications_screen.dart';
import '../auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/venue_model.dart';
import '../../providers/venue_provider.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';
import '../../providers/auth_provider.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/models/match_model.dart';
import '../../widgets/match_ui.dart';
import '../../widgets/bounce_interaction.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/brand_header.dart';
import '../venues/venue_detail_screen.dart';
import '../notifications/notifications_screen.dart';

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
  String selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'Tất cả',
    'Cầu lông',
    'Pickleball',
    'Bóng đá',
    'Bóng rổ',
    'Bóng chuyền',
    'Tennis',
    'Padel',
  ];

  late Future<List<OpenMatch>> _featuredMatchesFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _featuredMatchesFuture = ApiMatchRepository().list();
  }

  void _onSearchChanged() {
    context.read<VenueProvider>().onSearchChanged(_searchController.text);
  }

  int? _getSportId(String cat, [List<SportCategoryModel>? apiSports]) {
    if (cat == 'Tất cả') return null;
    if (apiSports != null && apiSports.isNotEmpty) {
      final match = apiSports.where((s) {
        final n = s.name.toLowerCase();
        final c = cat.toLowerCase();
        if (c == 'cầu lông' && (n.contains('cầu lông') || n.contains('badminton'))) return true;
        if (c == 'pickleball' && n.contains('pickleball')) return true;
        if (c == 'bóng đá' && (n.contains('bóng đá') || n.contains('football') || n.contains('soccer'))) return true;
        if (c == 'bóng rổ' && (n.contains('bóng rổ') || n.contains('basketball'))) return true;
        if (c == 'bóng chuyền' && (n.contains('bóng chuyền') || n.contains('volleyball'))) return true;
        if (c == 'tennis' && n.contains('tennis')) return true;
        if (c == 'padel' && n.contains('padel')) return true;
        return n.contains(c);
      }).firstOrNull;
      if (match != null) return match.id;
    }

    if (cat == 'Cầu lông' || cat.contains('Badminton')) return 1;
    if (cat == 'Pickleball') return 2;
    if (cat == 'Bóng đá' || cat.contains('Football') || cat.contains('Soccer')) return 3;
    if (cat == 'Bóng rổ' || cat.contains('Basketball')) return 4;
    if (cat == 'Bóng chuyền' || cat.contains('Volleyball')) return 5;
    if (cat == 'Tennis') return 6;
    if (cat == 'Padel') return 7;
    return null;
  }

  IconData _getCategoryIcon(String cat) {
    if (cat == 'Tất cả') return Icons.grid_view_rounded;
    if (cat == 'Cầu lông' || cat.contains('Badminton')) return Icons.sports_tennis_rounded;
    if (cat == 'Pickleball') return Icons.sports_baseball_rounded;
    if (cat == 'Bóng đá' || cat.contains('Football')) return Icons.sports_soccer_rounded;
    if (cat == 'Bóng rổ' || cat.contains('Basketball')) return Icons.sports_basketball_rounded;
    if (cat == 'Bóng chuyền' || cat.contains('Volleyball')) return Icons.sports_volleyball_rounded;
    if (cat == 'Tennis') return Icons.sports_tennis_rounded;
    if (cat == 'Padel') return Icons.sports_handball_rounded;
    return Icons.tune_rounded;
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
      appBar: SportSpotUnifiedHeader(
        screenName: 'Khám Phá Sân',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF111315)),
            tooltip: 'Thông báo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
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
                      child: Builder(
                        builder: (ctx) {
                          final auth = ctx.watch<AuthProvider>();
                          final user = auth.currentUser;
                          final isGuest = auth.isGuest || user == null;
                          final displayName = isGuest ? 'Khách vãng lai' : (user.fullName.isNotEmpty ? user.fullName : 'Hội viên');
                          final loc = ctx.watch<VenueProvider>().currentLocationName;

                          return Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00A859),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: const Color(0xFF00A859),
                                  backgroundImage: (!isGuest && user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child: isGuest
                                      ? const Icon(Icons.person_outline_rounded, size: 17, color: Colors.white)
                                      : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                          ? null
                                          : Text(
                                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(isGuest ? Icons.person_pin_circle_outlined : Icons.verified, size: 14, color: const Color(0xFF00A859)),
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
                                            loc,
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
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right Utility Control: Radius
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
                    final auth = context.read<AuthProvider>();
                    if (!auth.isAuthenticated) {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      if (!mounted || !auth.isAuthenticated) return;
                    }
                    if (!context.mounted) return;
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => VenueApplicationsScreen(onStatusRefresh: auth.refreshProfile)));
                    if (mounted) await auth.refreshProfile();
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
                        letterSpacing: 0,
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
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return BounceTap(
                      onTap: () {
                        setState(() => selectedCategory = cat);
                        final venueProv = context.read<VenueProvider>();
                        venueProv.selectSport(_getSportId(cat, venueProv.sports));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF111315))
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? const Color(0xFF333846) : const Color(0xFFD1D5DB)),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              size: 16,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF111315) : Colors.white)
                                  : const Color(0xFF00A859),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              cat,
                              style: TextStyle(
                                fontFamily: AppTheme.headingFont,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? const Color(0xFF111315) : Colors.white)
                                    : (isDark ? const Color(0xFFF6F6F3) : const Color(0xFF1F2937)),
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

              // Featured Venues Section
              Builder(
                builder: (context) {
                  final venueProvider = context.watch<VenueProvider>();
                  final bool hasLiveApi = venueProvider.hasLiveApi;
                  final List<SportSpotVenue> displayVenues = hasLiveApi
                      ? venueProvider.venues.map((v) => v.toSportSpotVenue()).toList()
                      : SportSpotMockData.venues.where((v) {
                          final sportId = _getSportId(selectedCategory, venueProvider.sports);
                          if (sportId == null) return true;
                          final disc = v.disciplines.map((d) => d.toLowerCase()).toList();
                          if (sportId == 1 && (disc.contains('badminton') || disc.contains('cầu lông'))) return true;
                          if (sportId == 2 && disc.contains('pickleball')) return true;
                          if (sportId == 3 && (disc.contains('football') || disc.contains('soccer') || disc.contains('bóng đá'))) return true;
                          if (sportId == 4 && (disc.contains('basketball') || disc.contains('bóng rổ'))) return true;
                          if (sportId == 5 && (disc.contains('volleyball') || disc.contains('bóng chuyền'))) return true;
                          if (sportId == 6 && disc.contains('tennis')) return true;
                          if (sportId == 7 && disc.contains('padel')) return true;
                          return false;
                        }).toList();

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
                                      letterSpacing: 0,
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
                        Column(
                          children: const [
                            SkeletonCard(height: 220),
                            SizedBox(height: 14),
                            SkeletonCard(height: 220),
                          ],
                        )
                      else if (displayVenues.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.sports_outlined, size: 42, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                              const SizedBox(height: 10),
                              Text(
                                'Không có sân phù hợp với bộ môn này',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF111315),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hãy thử chọn bán kính rộng hơn hoặc bộ môn khác',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
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
                        letterSpacing: 0,
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
              FutureBuilder<List<OpenMatch>>(
                future: _featuredMatchesFuture,
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  final match = list.isNotEmpty ? list.first : null;
                  final hasMatch = match != null;

                  return Container(
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00A859).withValues(alpha: 0.12),
                            border: Border.all(color: const Color(0xFF00A859), width: 2),
                          ),
                          child: Icon(
                            hasMatch ? matchSportIcon(match.sportId) : Icons.sports_tennis_rounded,
                            color: const Color(0xFF00A859),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      hasMatch ? match.venue : 'Mở Kèo Thể Thao Mới',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
                                    child: Text(
                                      hasMatch ? match.skill : 'Kèo Mở',
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF00A859), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasMatch
                                    ? '${match.sport} • ${match.slots.join(', ')}'
                                    : 'Tìm bạn cùng chơi và chia sẻ chi phí tiền sân',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.groups_rounded, size: 15, color: Color(0xFF00A859)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      hasMatch
                                          ? 'Thiếu ${match.remaining} người (${match.joined}/${match.needed})'
                                          : 'Đang mở tuyển khắp khu vực',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF00A859), fontWeight: FontWeight.w700),
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
                          child: Text(hasMatch ? 'Vào kèo' : 'Tạo kèo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                },
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
                          letterSpacing: 0,
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
                    BounceTap(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VenueDetailScreen(venue: venue),
                          ),
                        );
                      },
                      child: ElevatedButton(
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
