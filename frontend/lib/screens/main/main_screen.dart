import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../auth/phone_input_screen.dart';
import '../booking/court_slots_screen.dart';
import '../profile/profile_screen.dart';

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
      _buildPlaceholderTab('Tìm Kèo Vãng Lai', Icons.groups_rounded, 'Khám phá các ca đấu đang tìm người quanh bạn'),
      _buildPlaceholderTab('Vé Đặt Của Tôi', Icons.confirmation_number_rounded, 'Xem mã QR và vé điện tử ngoại tuyến'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SportSpot'),
        actions: [
          if (isGuest)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18, color: AppTheme.accentBlue),
              label: const Text('Đăng nhập', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner chào mừng & Thông tin Module 3
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.pastelBlue, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module 3: Đặt Sân Chống Trùng Lịch',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lưới ma trận 60p, chọn tối đa 3 slot liên tiếp, hold timer 5 phút & concurrency lock.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textGray, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tiêu đề danh sách sân thử nghiệm
            const Text(
              'Chọn sân để trải nghiệm đặt chỗ (Module 3):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),

            // Sân mẫu 1: Cầu Lông Cầu Giấy
            _buildVenueCard(
              context: context,
              venueId: 1,
              subVenueId: 1,
              venueName: 'CLB Cầu Lông Cầu Giấy',
              subVenueName: 'Sân Thảm 1',
              sportName: 'Cầu lông',
              address: 'Số 35 Trần Quý Kiên, Dịch Vọng, Cầu Giấy, Hà Nội',
              priceRange: '90.000 đ - 120.000 đ / slot',
              icon: Icons.sports_tennis_rounded,
            ),

            const SizedBox(height: 12),

            // Sân mẫu 2: Sân Bóng Đá Mini PVV
            _buildVenueCard(
              context: context,
              venueId: 2,
              subVenueId: 4,
              venueName: 'Sân Bóng Đá Mini PVV',
              subVenueName: 'Sân Cỏ 7A',
              sportName: 'Bóng đá mini',
              address: 'Số 72 Trần Thái Tông, Dịch Vọng Hậu, Cầu Giấy, Hà Nội',
              priceRange: '350.000 đ - 600.000 đ / slot',
              icon: Icons.sports_soccer_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard({
    required BuildContext context,
    required int venueId,
    required int subVenueId,
    required String venueName,
    required String subVenueName,
    required String sportName,
    required String address,
    required String priceRange,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accentBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sportName • $subVenueName',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Text(
                priceRange,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final provider = context.read<BookingProvider>();
                provider.setVenueInfo(
                  venueId: venueId,
                  subVenueId: subVenueId,
                  venueName: venueName,
                  subVenueName: subVenueName,
                  sportName: sportName,
                  address: address,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourtSlotsScreen()),
                );
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('Xem Lưới Khung Giờ & Đặt Sân', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
              Icon(icon, size: 64, color: AppTheme.textGray.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark),
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
