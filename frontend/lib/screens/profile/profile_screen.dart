import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sportspot_mock_data.dart';
import '../../widgets/confirm_action_sheet.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isFindMatch = true;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
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
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thông số thi đấu, chỉ số kỹ năng và ví điện tử.',
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
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(SportSpotMockData.userNam),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF111315),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nam Nguyen',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 18, color: Color(0xFF00A859)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quận Cầu Giấy, Hà Nội',
                      style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A859).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '⚡ Hội viên SportSpot Pro',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF00A859),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatCard('28', 'Trận đấu', textColor, cardColor, borderColor, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('56h', 'Giờ ra sân', const Color(0xFF00A859), cardColor, borderColor, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('1.4M', 'Tiết kiệm', const Color(0xFFF59E0B), cardColor, borderColor, isDark),
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
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '320,000 VND',
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00A859),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('⚡ Giả lập nạp tiền tức thì qua VNPay / MoMo'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color(0xFF111315),
                          ),
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

              // Skill Ratings Breakdown
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
                      'Đánh giá kỹ năng & Xác thực',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 14),
                    _buildSkillTile('Cầu lông', 'Nâng cao 4.0 • Kiểm định bởi HLV', 0.85, const Color(0xFF00A859), isDark, textColor, mutedColor),
                    const SizedBox(height: 12),
                    _buildSkillTile('Pickleball', 'Trung cấp 3.5 • Đồng bộ DUPR', 0.70, const Color(0xFF00C853), isDark, textColor, mutedColor),
                    const SizedBox(height: 12),
                    _buildSkillTile('Bóng đá mini', 'Hạng B+ • Đã ghi 14 bàn thắng', 0.78, const Color(0xFFF59E0B), isDark, textColor, mutedColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                        value: isFindMatch,
                        onChanged: (val) => setState(() => isFindMatch = val),
                        title: Text(
                          'Sẵn sàng ghép trận nhanh',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        subtitle: Text(
                          'Cho phép đội trưởng gần bạn gửi lời mời',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                        activeThumbColor: const Color(0xFF00A859),
                      ),
                      Divider(height: 1, color: borderColor),
                      SwitchListTile(
                        value: notificationsEnabled,
                        onChanged: (val) => setState(() => notificationsEnabled = val),
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

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await SportSpotConfirmSheet.show(
                      context,
                      title: 'Xác nhận Đăng Xuất',
                      message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản SportSpot trên thiết bị này?',
                      confirmLabel: 'Đăng Xuất',
                      cancelLabel: 'Ở lại',
                      icon: Icons.logout_rounded,
                      actionType: ConfirmActionType.destructive,
                    );
                    if (!mounted) return;
                    if (confirmed == true) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Đã đăng xuất khỏi tài khoản SportSpot'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('Đăng Xuất', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w800)),
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
                fontSize: 22,
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
