import 'package:flutter/material.dart';
import '../../data/sportspot_mock_data.dart';
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hồ Sơ Cá Nhân', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Thông số thi đấu, chỉ số kỹ năng và ví điện tử.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),

              // User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: const NetworkImage(SportSpotMockData.userNam),
                          backgroundColor: Colors.grey.shade700,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF111315),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Nam Nguyen', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.verified, size: 18, color: Color(0xFF00A859)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text('Quận Cầu Giấy, Hà Nội', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111315).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚡ Hội viên SportSpot Pro',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF111315),
                          fontWeight: FontWeight.bold,
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
                  _buildStatCard('28', 'Trận đấu', const Color(0xFF111315), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('56h', 'Giờ ra sân', const Color(0xFF10B981), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('1.4M', 'Tiết kiệm', Colors.amber, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VÍ ĐIỆN TỬ SPORTSPOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                        SizedBox(height: 4),
                        Text('320,000 VND', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Giả lập nạp tiền tức thì qua VNPay / MoMo'),
                            backgroundColor: Color(0xFF111315),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111315),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('+ Nạp Tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  color: isDark ? const Color(0xFF191A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đánh giá kỹ năng & Xác thực', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    _buildSkillTile('Cầu lông', 'Nâng cao 4.0 • Kiểm định bởi HLV', 0.85, const Color(0xFF111315), isDark),
                    const SizedBox(height: 12),
                    _buildSkillTile('Pickleball', 'Trung cấp 3.5 • Đồng bộ DUPR', 0.70, const Color(0xFF10B981), isDark),
                    const SizedBox(height: 12),
                    _buildSkillTile('Bóng đá mini', 'Hạng B+ • Đã ghi 14 bàn thắng', 0.78, Colors.amber, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Settings
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191A1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: isFindMatch,
                        onChanged: (val) => setState(() => isFindMatch = val),
                        title: const Text('Sẵn sàng ghép trận nhanh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Cho phép đội trưởng gần bạn gửi lời mời', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: const Color(0xFF111315),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: notificationsEnabled,
                        onChanged: (val) => setState(() => notificationsEnabled = val),
                        title: const Text('Nhắc nhở trận đấu & Thông báo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Nhận thông báo nhắc nhở 2 tiếng trước giờ vào sân', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeThumbColor: const Color(0xFF111315),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                  label: const Text('Xem giới thiệu & Hướng dẫn bắt đầu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản SportSpot')),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('Đăng Xuất', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191A1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTile(String title, String subtitle, double progress, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.grey.shade200,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
