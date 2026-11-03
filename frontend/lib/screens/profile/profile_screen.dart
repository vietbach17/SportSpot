import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/confirm_action_sheet.dart';
import '../auth/phone_input_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../tickets/cancel_ticket_dialog.dart';
import '../tickets/qr_scanner_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import '../payment/wallet_history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/brand_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFindMatch = true;
  bool _notificationsEnabled = true;
  bool _hasInitializedSettings = false;

  void _showEditProfileSheet(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final sportsCtrl = TextEditingController(text: user?.favoriteSports ?? 'Cầu lông, Pickleball');
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
                Text(
                  'Chỉnh Sửa Hồ Sơ Cá Nhân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật thông tin định danh và bộ môn yêu thích trên SportSpot.',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
                const SizedBox(height: 18),
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
                    labelText: 'Địa chỉ Email',
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
                            );
                            setSheetState(() => isSaving = false);
                            if (ctx.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Cập nhật hồ sơ thành công!'
                                        : (auth.errorMessage ?? 'Cập nhật thất bại'),
                                  ),
                                  backgroundColor: success ? const Color(0xFF00A859) : Colors.redAccent,
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

    if (!_hasInitializedSettings && user != null) {
      _isFindMatch = user.isFindMatchEnabled;
      _hasInitializedSettings = true;
    }

    final matchCount = ticketProvider.tickets.length;
    final hoursCount = ticketProvider.tickets.fold<int>(0, (sum, t) => sum + (t.timeSlots.length.clamp(1, 4)));
    final walletDisplay = ticketProvider.walletBalance > 0
        ? CancelTicketDialog.formatVnd(ticketProvider.walletBalance)
        : CancelTicketDialog.formatVnd(user?.walletBalance ?? 0);

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
              Text(
                'Hồ Sơ Cá Nhân',
                style: TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGuest
                    ? 'Thông số thi đấu và ví điện tử (Chế độ khách vãng lai).'
                    : 'Thông số thi đấu, chỉ số kỹ năng và ví điện tử.',
                style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w500),
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
                        Container(
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
                              MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                            );
                          },
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Đăng Nhập / Đăng Ký (OTP)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
                          InkWell(
                            onTap: () => _showEditProfileSheet(context, auth),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 14),
                                  SizedBox(width: 4),
                                  Text('Sửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatCard(
                    isGuest ? '0' : '$matchCount',
                    'Trận đấu',
                    textColor,
                    cardColor,
                    borderColor,
                    isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    isGuest ? '0h' : '${hoursCount}h',
                    'Giờ ra sân',
                    const Color(0xFF00A859),
                    cardColor,
                    borderColor,
                    isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    isGuest ? '0 đ' : walletDisplay,
                    'Ví cọc/hoàn',
                    const Color(0xFFF59E0B),
                    cardColor,
                    borderColor,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet Card
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VÍ ĐIỆN TỬ SPORTSPOT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: mutedColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          walletDisplay,
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00A859),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text('+ Nạp Tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Staff/Admin Management Tool
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
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

              // Preferences Settings
              Container(
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isFindMatch,
                        onChanged: (val) async {
                          setState(() => _isFindMatch = val);
                          if (!isGuest) {
                            await auth.updateProfile(isFindMatchEnabled: val);
                          }
                        },
                        title: Text(
                          'Sẵn sàng ghép trận nhanh',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        subtitle: Text(
                          'Cho phép đội trưởng gần bạn gửi lời mời vào kèo',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                        activeThumbColor: const Color(0xFF00A859),
                      ),
                      Divider(height: 1, color: borderColor),
                      SwitchListTile(
                        value: _notificationsEnabled,
                        onChanged: (val) => setState(() => _notificationsEnabled = val),
                        title: Text(
                          'Nhắc nhở trận đấu & Thông báo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        subtitle: Text(
                          'Nhận thông báo nhắc nhở 2 tiếng trước giờ vào sân',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                        activeThumbColor: const Color(0xFF00A859),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB), size: 20),
                        title: Text(
                          'Hộp Thư Thông Báo & Nhắc Lịch',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // View Welcome Onboarding Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                  icon: const Icon(Icons.preview_rounded, size: 18),
                  label: const Text('Xem giới thiệu & Hướng dẫn bắt đầu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Logout / Login CTA button
              if (!isGuest)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: AppTheme.destructiveButtonStyle(borderRadius: 12),
                    onPressed: () async {
                      final confirmed = await SportSpotConfirmSheet.show(
                        context,
                        title: 'Xác nhận Đăng Xuất',
                        message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản SportSpot trên thiết bị này?',
                        confirmLabel: 'Đăng Xuất',
                        cancelLabel: 'Ở lại',
                        icon: Icons.logout_rounded,
                        actionType: ConfirmActionType.destructive,
                      );
                      if (!context.mounted) return;
                      if (confirmed == true) {
                        await auth.logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đăng xuất khỏi tài khoản SportSpot'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Đăng Xuất',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
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
