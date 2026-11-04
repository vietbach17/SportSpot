import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/floating_bottom_bar.dart';
import '../admin/admin_hub_screen.dart';
import '../home/home_screen.dart';
import '../matches/match_feed_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../tickets/my_tickets_screen.dart';
import '../tickets/qr_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.isGuest ? 'Guest' : (auth.currentUser?.role ?? 'Player');

    // Tự động đồng bộ index khi vai trò đăng nhập thay đổi
    if (_currentRole != role) {
      _currentRole = role;
      _currentIndex = 0;
    }

    final List<Widget> pages;
    final List<Map<String, dynamic>> navItems;

    switch (role) {
      case 'Admin':
        pages = [
          const AdminHubScreen(key: ValueKey('admin_stats'), initialTabIndex: 0),
          const AdminHubScreen(key: ValueKey('admin_users'), initialTabIndex: 2),
          const AdminHubScreen(key: ValueKey('admin_venues'), initialTabIndex: 1),
          const ProfileScreen(),
        ];
        navItems = [
          {
            'icon': Icons.analytics_outlined,
            'activeIcon': Icons.analytics_rounded,
            'label': 'Thống kê',
          },
          {
            'icon': Icons.people_outline_rounded,
            'activeIcon': Icons.people_rounded,
            'label': 'Người dùng',
          },
          {
            'icon': Icons.approval_outlined,
            'activeIcon': Icons.approval_rounded,
            'label': 'Duyệt sân',
          },
          {
            'icon': Icons.admin_panel_settings_outlined,
            'activeIcon': Icons.admin_panel_settings_rounded,
            'label': 'Hệ thống',
          },
        ];
        break;

      case 'Owner':
        pages = [
          const OwnerDashboardScreen(),
          Consumer<TicketProvider>(
            builder: (ctx, ticketProv, _) => QrScannerScreen(provider: ticketProv),
          ),
          const ProfileScreen(),
        ];
        navItems = [
          {
            'icon': Icons.dashboard_outlined,
            'activeIcon': Icons.dashboard_rounded,
            'label': 'Doanh thu',
          },
          {
            'icon': Icons.qr_code_scanner_outlined,
            'activeIcon': Icons.qr_code_scanner_rounded,
            'label': 'Soát vé QR',
          },
          {
            'icon': Icons.account_circle_outlined,
            'activeIcon': Icons.account_circle_rounded,
            'label': 'Chủ sân',
          },
        ];
        break;

      case 'VenueStaff':
        pages = [
          Consumer<TicketProvider>(
            builder: (ctx, ticketProv, _) => QrScannerScreen(provider: ticketProv),
          ),
          const ProfileScreen(),
        ];
        navItems = [
          {
            'icon': Icons.qr_code_scanner_outlined,
            'activeIcon': Icons.qr_code_scanner_rounded,
            'label': 'Soát vé QR',
          },
          {
            'icon': Icons.badge_outlined,
            'activeIcon': Icons.badge_rounded,
            'label': 'Lễ tân',
          },
        ];
        break;

      case 'Player':
      case 'Guest':
      default:
        pages = [
          HomeScreen(
            onNavigateToMatches: () => setState(() => _currentIndex = 1),
          ),
          const MatchFeedScreen(),
          const MyTicketsScreen(),
          const ProfileScreen(),
        ];
        navItems = [
          {
            'icon': Icons.sports_tennis_rounded,
            'activeIcon': Icons.sports_tennis_rounded,
            'label': 'Trang chủ',
          },
          {
            'icon': Icons.groups_outlined,
            'activeIcon': Icons.groups_rounded,
            'label': 'Tìm kèo',
          },
          {
            'icon': Icons.confirmation_number_outlined,
            'activeIcon': Icons.confirmation_number_rounded,
            'label': 'Vé của tôi',
          },
          {
            'icon': Icons.account_circle_outlined,
            'activeIcon': Icons.account_circle_rounded,
            'label': 'Tài khoản',
          },
        ];
        break;
    }

    final safeIndex = (_currentIndex < pages.length) ? _currentIndex : 0;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          FloatingBottomNavBar(
            currentIndex: safeIndex,
            customItems: navItems,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ],
      ),
    );
  }
}
