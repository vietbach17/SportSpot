import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_input_screen.dart';
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
      _buildHomePlaceholder(context, isGuest),
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

  Widget _buildHomePlaceholder(BuildContext context, bool isGuest) {
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_soccer_rounded, size: 54, color: AppTheme.accentBlue),
              ),
              const SizedBox(height: 20),
              Text(
                isGuest ? 'Đang duyệt với tư cách Khách (Guest Mode)' : 'Chào mừng bạn đến với SportSpot!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Module 1 (Xác thực & Hồ sơ) đã sẵn sàng.\nBạn có thể chuyển sang tab "Cá nhân" để xem thông tin và bật Chế độ tìm kèo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textGray, height: 1.5),
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
              Icon(icon, size: 64, color: AppTheme.textGray.withOpacity(0.5)),
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
