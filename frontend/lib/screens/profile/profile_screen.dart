import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/models/venue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/venue_provider.dart';
import '../auth/login_screen.dart';
import '../booking/court_slots_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../payment/wallet_history_screen.dart';
import '../settings/settings_screen.dart';
import '../tickets/cancel_ticket_dialog.dart';
import '../tickets/qr_scanner_screen.dart';
import '../venues/venue_detail_screen.dart';
import '../../widgets/brand_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final IFavoriteRepository _favoriteRepo = ApiFavoriteRepository();
  List<int> _favoriteVenueIds = [];
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoriteRepo.getFavoriteVenueIds();
      if (mounted) setState(() => _favoriteVenueIds = ids);
    } catch (_) {}
  }

  Future<void> _toggleFavorite(int venueId) async {
    await _favoriteRepo.toggleFavorite(venueId);
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật danh sách sân yêu thích'), duration: Duration(seconds: 1)),
      );
    }
  }

  static const List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80',
  ];

  void _showEditProfileSheet(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final sportsCtrl = TextEditingController(text: user?.favoriteSports ?? 'Cầu lông, Pickleball');
    final avatarCtrl = TextEditingController(text: user?.avatarUrl ?? '');
    String selectedAvatar = user?.avatarUrl ?? _avatarPresets.first;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final cardColor = isDark ? const Color(0xFF191A20) : Colors.white;
          final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
          final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chỉnh Sửa Tài Khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cập nhật ảnh đại diện, thông tin định danh và bộ môn yêu thích.',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 16),

                  // 1. Avatar Preview & Preset Selection
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00A859), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF00A859).withValues(alpha: 0.15),
                            backgroundImage: selectedAvatar.isNotEmpty ? NetworkImage(selectedAvatar) : null,
                            child: selectedAvatar.isEmpty
                                ? const Icon(Icons.person, size: 36, color: Color(0xFF00A859))
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chọn ảnh đại diện thể thao gợi ý:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _avatarPresets.map((presetUrl) {
                              final isSelected = selectedAvatar == presetUrl;
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedAvatar = presetUrl;
                                    avatarCtrl.text = presetUrl;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF00A859) : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundImage: NetworkImage(presetUrl),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),



                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ Email (Nhận thông báo & OTP)',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sportsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Môn thể thao yêu thích (phân cách bằng dấu phẩy)',
                      hintText: 'Cầu lông, Pickleball, Bóng đá mini',
                      prefixIcon: const Icon(Icons.sports_tennis_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A859),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              final success = await auth.updateProfile(
                                fullName: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                favoriteSports: sportsCtrl.text.trim(),
                                avatarUrl: selectedAvatar.trim(),
                              );
                              setSheetState(() => isSaving = false);
                              if (ctx.mounted) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Cập nhật tài khoản thành công!'
                                          : (auth.errorMessage ?? 'Cập nhật thất bại'),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final auth = context.watch<AuthProvider>();
    final ticketProvider = context.watch<TicketProvider>();
    final user = auth.currentUser;
    final isGuest = auth.isGuest || user == null;

    VenueProvider? venueProvider;
    try {
      venueProvider = context.watch<VenueProvider>();
    } catch (_) {
      venueProvider = null;
    }
    final favoriteVenues = venueProvider != null
        ? venueProvider.venues.where((v) => _favoriteVenueIds.contains(v.id)).toList()
        : <VenueItemModel>[];

    final matchCount = isGuest
        ? (ticketProvider.tickets.isNotEmpty ? ticketProvider.tickets.length : 2)
        : ticketProvider.tickets.length;
    final hoursCount = isGuest
        ? (ticketProvider.tickets.isNotEmpty ? ticketProvider.tickets.fold<int>(0, (sum, t) => sum + (t.timeSlots.length.clamp(1, 4))) : 3)
        : ticketProvider.tickets.fold<int>(0, (sum, t) => sum + (t.timeSlots.length.clamp(1, 4)));
    final walletDisplay = CancelTicketDialog.formatVnd(ticketProvider.walletBalance);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const SportSpotUnifiedHeader(
        screenName: 'Hồ Sơ Cá Nhân',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Tiêu đề "Tài Khoản" + Nút Cài Đặt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tài Khoản',
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGuest
                              ? 'Thông số thi đấu và ví điện tử (Chế độ khách vãng lai).'
                              : 'Thông số thi đấu, chỉ số kỹ năng và ví điện tử.',
                          style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: textColor, size: 24),
                    tooltip: 'Cài đặt hệ thống',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
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
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!isGuest) _showEditProfileSheet(context, auth);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00A859), width: 2.5),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF00A859).withValues(alpha: 0.15),
                              backgroundImage: (!isGuest && user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: isGuest
                                  ? const Icon(Icons.person_outline_rounded, size: 40, color: Color(0xFF00A859))
                                  : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                      ? null
                                      : Text(
                                          (user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U'),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF00A859),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        if (!isGuest)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => _showEditProfileSheet(context, auth),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111315),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isGuest ? 'Khách Vãng Lai (Guest)' : (user.fullName.isNotEmpty ? user.fullName : 'Hội Viên'),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isGuest ? Icons.person_pin_circle_outlined : Icons.verified,
                          size: 18,
                          color: const Color(0xFF00A859),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGuest
                          ? 'Đăng nhập để đặt sân, ghép kèo và tích điểm'
                          : (user.phoneNumber.isNotEmpty
                              ? user.phoneNumber
                              : ((user.email?.isNotEmpty ?? false) ? user.email! : 'Thành viên SportSpot')),
                      style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    if (isGuest)
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Đăng Nhập / Đăng Ký', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A859),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A859).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              user.role == 'VenueStaff'
                                  ? '🛠️ Lễ Tân / Quản Lý Sân'
                                  : (user.role == 'Admin' ? '👑 Quản Trị Viên' : '⚡ Hội viên SportSpot Pro'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00A859),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showEditProfileSheet(context, auth),
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Match Stats Row
              Row(
                children: [
                  _buildStatCard(matchCount.toString(), 'Trận đấu', const Color(0xFF111315), cardColor, borderColor, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('${hoursCount}h', 'Giờ ra sân', const Color(0xFF00A859), cardColor, borderColor, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard(walletDisplay, 'Ví cọc/hoàn', const Color(0xFFF59E0B), cardColor, borderColor, isDark),
                ],
              ),
              const SizedBox(height: 14),

              // Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VÍ ĐIỆN TỬ SPORTSPOT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: mutedColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            walletDisplay,
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00A859),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Vui lòng đăng nhập để sử dụng và nạp tiền vào ví SportSpot!'),
                              action: SnackBarAction(
                                label: 'Đăng nhập',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_card_rounded, size: 16),
                      label: const Text('+ Nạp Tiền', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ==========================================
              // DANH SÁCH SÂN YÊU THÍCH CỦA TÔI
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sân Yêu Thích (${favoriteVenues.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        if (favoriteVenues.isNotEmpty)
                          InkWell(
                            onTap: _loadFavorites,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                'Làm mới',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (favoriteVenues.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF22242B) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.favorite_border_rounded, size: 36, color: mutedColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có sân yêu thích nào',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy bấm biểu tượng ❤️ tại trang chi tiết các sân thể thao để lưu lại vào đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11.5, color: mutedColor, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favoriteVenues.length,
                        separatorBuilder: (_, __) => Divider(height: 20, color: borderColor),
                        itemBuilder: (ctx, idx) {
                          final v = favoriteVenues[idx];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VenueDetailScreen(venue: v),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                    child: Image.network(
                                      v.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.sports_tennis_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00A859).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              v.sportName,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A859)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 2),
                                          Text(
                                            v.rating.toStringAsFixed(1),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        v.address,
                                        style: TextStyle(fontSize: 11, color: mutedColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => _toggleFavorite(v.id),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CourtSlotsScreen(venueId: v.id),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        child: const Text('Đặt sân', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // Staff Ticket QR Scanner (Dành cho Lễ tân / Quản lý)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
                    ),
                    title: Text(
                      'Soát Vé QR (Dành Cho Lễ Tân / Quản Lý Sân)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Quét mã QR của người chơi để điểm danh & giải ngân cọc Escrow',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrScannerScreen(
                            provider: context.read<TicketProvider>(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Owner Dashboard Access
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF16A34A)),
                    ),
                    title: Text(
                      'Bảng Điều Khiển Chủ Sân (Owner Dashboard)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Thống kê doanh thu, cọc Escrow & quản lý bảo trì sân con',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OwnerDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cài Đặt Hệ Thống Card (Mới: Đáp ứng yêu cầu thứ 3 của người dùng)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF6366F1)),
                    ),
                    title: Text(
                      'Cài Đặt Hệ Thống & Tùy Chọn',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Giao diện Tối/Sáng, ghép trận nhanh, đổi mật khẩu & tài khoản',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skill Ratings Breakdown (Chỉ hiển thị cho Hội viên, ẩn đối với khách vãng lai)
              if (!isGuest) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
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
                      Text(
                        'Bộ Môn & Đánh Giá Kỹ Năng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 14),
                      _buildSkillTile('Cầu lông', 'Nâng cao 4.0 • Xác thực bởi Host', 0.85, const Color(0xFF00A859), isDark, textColor, mutedColor),
                      const SizedBox(height: 12),
                      _buildSkillTile('Pickleball', 'Trung cấp 3.5 • DUPR Rating', 0.70, const Color(0xFF00C853), isDark, textColor, mutedColor),
                      const SizedBox(height: 12),
                      _buildSkillTile('Bóng đá mini', 'Hạng B+ • Tốc độ & Thể lực', 0.78, const Color(0xFFF59E0B), isDark, textColor, mutedColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
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
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTile(
    String title,
    String subtitle,
    double progress,
    Color color,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: mutedColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? const Color(0xFF242834) : const Color(0xFFE5E7EB),
            color: color,
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
