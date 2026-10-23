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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A22) : const Color(0xFFFAF8FF),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242834) : Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.verified, size: 14, color: Color(0xFF2563EB)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        'Cầu Giấy, Hà Nội',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

                  // Right Utility Pills
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _cycleRadius,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242834) : Colors.white,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore_outlined, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                '$radiusKm km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242834) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar Pill
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sân, cụm sân hoặc quận...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E3342) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune_rounded, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Quick Tactical Shortcuts
              Row(
                children: [
                  _buildQuickAction('Đăng ký sân', Icons.add_circle_outline_rounded, const Color(0xFF2563EB), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mở mẫu đăng ký cụm sân mới')),
                    );
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAction('Tạo trận', Icons.group_add_outlined, const Color(0xFF10B981), () {
                    if (widget.onNavigateToMatches != null) {
                      widget.onNavigateToMatches!();
                    }
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAction('Hỗ trợ', Icons.support_agent_rounded, Colors.grey, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hỗ trợ trực tuyến 24/7')),
                    );
                  }, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Category Filter Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = cat);
                        context.read<VenueProvider>().selectSport(_getSportId(cat));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF242834) : Colors.white),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
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
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: NetworkImage(SportSpotMockData.heroBanner),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xEB111319)],
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text('⚡ Instant Split', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text('Save 30%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                      Text('PRIME WEEKEND TURF', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text(
                                        'Book with Friends & Split Cost Instantly',
                                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
                              child: Row(
                                children: [
                                  const Text(
                                    'Featured Venues',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2E3D) : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      '${displayVenues.length}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (hasLiveApi ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(9999),
                                      border: Border.all(color: hasLiveApi ? const Color(0xFF10B981) : Colors.amber),
                                    ),
                                    child: Text(
                                      hasLiveApi ? 'LIVE API' : 'DEMO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: hasLiveApi ? const Color(0xFF10B981) : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<VenueProvider>().refreshVenues(),
                            child: const Text('Refresh', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (venueProvider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        ...displayVenues.map((venue) => _buildVenueCard(context, venue, isDark)),
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
                      'Open Matches Nearby',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onNavigateToMatches,
                    child: const Text('Find More', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(SportSpotMockData.coachMinh),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Coach Minh Le',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('Adv 4.0', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            'Badminton Doubles • 19:00 Tonight',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Row(
                            children: [
                              Icon(Icons.groups_rounded, size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '3/4 Players joined',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
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
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242834) : Colors.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildVenueCard(BuildContext context, SportSpotVenue venue, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VenueDetailScreen(venue: venue),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242834) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    venue.image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: const Color(0xFF1E212B),
                      child: const Center(
                        child: Icon(Icons.sports_tennis_rounded, color: Color(0xFF2563EB), size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${venue.rating}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(' (${venue.reviewCount})', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'From ${venue.priceFrom ~/ 1000}k/h',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${venue.address} • ${venue.distance}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${venue.slotsAvailableToday} slots open today',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
