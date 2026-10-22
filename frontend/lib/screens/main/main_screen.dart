import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/match_ui.dart';
import '../auth/phone_input_screen.dart';
import '../booking/court_slots_screen.dart';
import '../profile/profile_screen.dart';
import '../matches/match_feed_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthProvider>().isGuest;

    final List<Widget> pages = [
      _buildHomeScreen(context, isGuest),
      const MatchFeedScreen(),
      _buildPlaceholderTab(
        'Vé Đặt Của Tôi',
        Icons.confirmation_number_rounded,
        'Xem mã QR và vé điện tử ngoại tuyến',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_tennis_outlined),
            activeIcon: Icon(Icons.sports_tennis_rounded),
            label: 'Tìm kèo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Vé của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context, bool isGuest) {
    return MatchTheme(
      child: Scaffold(
        backgroundColor: MatchColors.canvas,
        appBar: AppBar(
          title: const SportSpotBrandTitle(),
          actions: [
            if (isGuest)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneInputScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.login_rounded,
                  size: 18,
                  color: MatchColors.blue,
                ),
                label: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: MatchColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                MatchHero(
                  eyebrow: 'KHÓA CHỐNG TRÙNG LỊCH',
                  title: 'Lưới Khung Giờ &\nĐặt Sân Tự Động',
                  subtitle:
                      'Chọn khung giờ trực quan, kiểm tra liên tiếp tối đa 3h, đồng hồ giữ chỗ 5 phút và chống trùng lịch tuyệt đối.',
                  footer: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CourtSlotsScreen(venueId: 1),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MatchColors.navy,
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Đặt Sân Cầu Lông Ngay'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CỤM SÂN THỂ THAO TIÊU BIỂU',
                  style: TextStyle(
                    fontSize: 10,
                    color: MatchColors.muted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _venueCard(
                  context: context,
                  venueId: 1,
                  title: 'CLB Cầu Lông Cầu Giấy',
                  sport: 'Cầu lông',
                  sportId: 1,
                  address: '35 Trần Quý Kiên, Cầu Giấy',
                  price: '90.000 đ - 120.000 đ/h',
                  rating: '4.9',
                  icon: Icons.sports_tennis_rounded,
                ),
                const SizedBox(height: 12),
                _venueCard(
                  context: context,
                  venueId: 2,
                  title: 'Sân Bóng Đá Mini PVV',
                  sport: 'Bóng đá mini',
                  sportId: 3,
                  address: '72 Trần Thái Tông, Cầu Giấy',
                  price: '350.000 đ - 600.000 đ/h',
                  rating: '4.7',
                  icon: Icons.sports_soccer_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _venueCard({
    required BuildContext context,
    required int venueId,
    required String title,
    required String sport,
    required int sportId,
    required String address,
    required String price,
    required String rating,
    required IconData icon,
  }) {
    return MatchSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourtSlotsScreen(venueId: venueId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: MatchColors.blue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MatchPill(sport, icon: matchSportIcon(sportId)),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: MatchColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: MatchColors.ink,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: MatchColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MatchColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
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

  Widget _buildPlaceholderTab(String title, IconData icon, String subtitle) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: AppTheme.textGray.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
