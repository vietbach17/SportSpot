import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/confirm_action_sheet.dart';
import '../notifications/notifications_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final email = auth.currentUser?.email ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cập nhật email trong Hồ sơ trước khi đổi mật khẩu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final otpCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isSendingOtp = false;
    bool isSubmitting = false;
    bool otpSent = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final cardColor = isDark ? const Color(0xFF1E2129) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF111315);
          final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Đổi Mật Khẩu',
              style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã xác thực OTP sẽ được gửi tới email:',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 14),
                  if (!otpSent) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSendingOtp
                            ? null
                            : () async {
                                setDlgState(() => isSendingOtp = true);
                                final sent = await auth.sendChangePasswordEmailOtp(email: email);
                                setDlgState(() {
                                  isSendingOtp = false;
                                  if (sent) otpSent = true;
                                });
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        sent
                                            ? 'Đã gửi mã OTP tới email $email!'
                                            : (auth.errorMessage ?? 'Gửi OTP thất bại'),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSendingOtp
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.mark_email_read_rounded, size: 18),
                        label: Text(isSendingOtp ? 'Đang gửi...' : 'Gửi mã OTP về Email'),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Nhập mã OTP (6 số)',
                        prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDlgState(() => obscure = !obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgContext),
                child: const Text('Hủy'),
              ),
              if (otpSent)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (otpCtrl.text.trim().length < 6 || newPasswordCtrl.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập OTP 6 số và mật khẩu từ 6 ký tự')),
                            );
                            return;
                          }
                          setDlgState(() => isSubmitting = true);
                          final ok = await auth.changePasswordWithEmailOtp(
                            email: email,
                            otpCode: otpCtrl.text.trim(),
                            newPassword: newPasswordCtrl.text.trim(),
                          );
                          setDlgState(() => isSubmitting = false);
                          if (ctx.mounted) {
                            Navigator.pop(dlgContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                                content: Text(
                                  ok
                                      ? 'Đổi mật khẩu thành công! Mật khẩu mới đã được cập nhật.'
                                      : (auth.errorMessage ?? 'Đổi mật khẩu thất bại'),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: Text(isSubmitting ? 'Đang lưu...' : 'Xác nhận Đổi'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE2E4EB);
    final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest || auth.currentUser == null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài Đặt Hệ Thống',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // 1. Nhóm Giao diện & Trải nghiệm (Chế độ Dark mode)
            _buildSectionHeader('GIAO DIỆN & TRẢI NGHIỆM', mutedColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: SwitchListTile(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (themeProvider.isDarkMode ? Colors.amber : const Color(0xFF6366F1)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: themeProvider.isDarkMode ? Colors.amber : const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Chế độ Giao diện Tối (Dark Mode)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Đang bật nền tối thể thao dịu mắt' : 'Đang bật nền sáng thanh lịch',
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
                activeColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Nhóm Kèo đấu & Thông báo (Từ hình 3)
            _buildSectionHeader('TÙY CHỌN TRẬN ĐẤU & THÔNG BÁO', mutedColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: auth.currentUser?.isFindMatchEnabled ?? true,
                    onChanged: isGuest
                        ? null
                        : (val) async {
                            await auth.updateProfile(isFindMatchEnabled: val);
                          },
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A859).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radar_rounded, color: Color(0xFF00A859), size: 20),
                    ),
                    title: Text(
                      'Sẵn sàng ghép trận nhanh',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Cho phép đội trưởng gần bạn gửi lời mời vào kèo',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    activeColor: const Color(0xFF16A34A),
                  ),
                  Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                  SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    title: Text(
                      'Nhắc nhở trận đấu & Thông báo',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Nhận thông báo nhắc nhở 2 tiếng trước giờ vào sân',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    activeColor: const Color(0xFF16A34A),
                  ),
                  Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF9333EA), size: 20),
                    ),
                    title: Text(
                      'Hộp Thư Thông Báo & Nhắc Lịch',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    subtitle: Text(
                      'Xem các thông báo trận đấu, cọc Escrow & khuyến mãi',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
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
            const SizedBox(height: 20),

            // 3. Nhóm Hướng dẫn & Hỗ trợ (Từ hình 3)
            _buildSectionHeader('HƯỚNG DẪN & THÔNG TIN', mutedColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
                title: Text(
                  'Xem giới thiệu & Hướng dẫn bắt đầu',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                ),
                subtitle: Text(
                  'Quy trình đặt sân, ký quỹ cọc Escrow và quét mã QR',
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. Nhóm Bảo mật & Tài khoản (Từ hình 3)
            _buildSectionHeader('BẢO MẬT & TÀI KHOẢN', mutedColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                children: [
                  if (!isGuest) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.password_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      title: Text(
                        'Đổi Mật Khẩu Tài Khoản',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      subtitle: Text(
                        'Xác thực mã OTP gửi về Email để đổi mật khẩu mới',
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => _showChangePasswordDialog(context, auth),
                    ),
                    Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                  ],
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    ),
                    title: Text(
                      isGuest ? 'Đăng Nhập Tài Khoản' : 'Đăng Xuất Khỏi Thiết Bị',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isGuest ? const Color(0xFF16A34A) : Colors.redAccent,
                      ),
                    ),
                    subtitle: Text(
                      isGuest
                          ? 'Đăng nhập để đồng bộ vé thi đấu và chỉ số kỹ năng'
                          : 'Đăng xuất tài khoản SportSpot trên thiết bị này',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () async {
                      if (isGuest) {
                        Navigator.pop(context);
                      } else {
                        final confirmed = await SportSpotConfirmSheet.show(
                          context,
                          title: 'Xác nhận Đăng Xuất',
                          message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản SportSpot trên thiết bị này?',
                          confirmLabel: 'Đăng Xuất',
                          cancelLabel: 'Ở lại',
                          icon: Icons.logout_rounded,
                          actionType: ConfirmActionType.destructive,
                        );
                        if (context.mounted && confirmed == true) {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đăng xuất khỏi tài khoản SportSpot'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
