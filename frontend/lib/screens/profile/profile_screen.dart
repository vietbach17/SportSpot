import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_input_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _availableSports = [
    'Cầu lông',
    'Pickleball',
    'Bóng đá mini',
    'Bóng rổ',
  ];

  Set<String> _selectedSports = {'Cầu lông', 'Bóng đá mini'};
  bool _isFindMatch = false;

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  void _loadLocalSettings() async {
    final user = context.read<AuthProvider>().currentUser;
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isFindMatch = user?.isFindMatchEnabled ?? prefs.getBool('is_find_match_enabled') ?? false;
      final savedSports = user?.favoriteSports ?? prefs.getString('favorite_sports') ?? 'Cầu lông,Bóng đá mini';
      _selectedSports = savedSports.split(',').map((e) => e.trim()).toSet();
    });
  }

  void _onToggleFindMatch(bool value) async {
    setState(() => _isFindMatch = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_find_match_enabled', value);

    final sportsStr = _selectedSports.join(',');
    await prefs.setString('favorite_sports', sportsStr);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isGuest) {
      await auth.updateProfile(
        isFindMatchEnabled: value,
        favoriteSports: sportsStr,
      );
    }
  }

  void _onToggleSport(String sport) async {
    setState(() {
      if (_selectedSports.contains(sport)) {
        if (_selectedSports.length > 1) {
          _selectedSports.remove(sport);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ít nhất 1 môn thể thao')),
          );
          return;
        }
      } else {
        _selectedSports.add(sport);
      }
    });

    final sportsStr = _selectedSports.join(',');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_sports', sportsStr);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isGuest) {
      await auth.updateProfile(favoriteSports: sportsStr);
    }
  }

  void _showEditProfileDialog() {
    final user = context.read<AuthProvider>().currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Địa chỉ Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              Navigator.pop(ctx);

              final success = await context.read<AuthProvider>().updateProfile(
                fullName: newName.isNotEmpty ? newName : null,
                email: newEmail.isNotEmpty ? newEmail : null,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Cập nhật thành công!' : 'Cập nhật thất bại'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa thông tin',
              onPressed: _showEditProfileDialog,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thẻ Card thông tin người dùng
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: isGuest
                    ? Column(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.pastelBlue,
                            child: Icon(Icons.person_outline_rounded, size: 40, color: AppTheme.accentBlue),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Khách vãng lai (Guest)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Đăng nhập để đặt sân, ghép trận và nhận thông báo nhắc lịch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                              );
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Đăng nhập / Đăng ký ngay'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppTheme.pastelBlue,
                            child: Text(
                              user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.accentBlue),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Người dùng SportSpot',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.phoneNumber ?? '',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textGray, fontWeight: FontWeight.w500),
                                ),
                                if (user?.email != null && user!.email!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email!,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.accentBlue),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pastelBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Vai trò: ${user?.role ?? "Player"}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Thẻ Ví tiền nếu đã đăng nhập
            if (!isGuest) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số dư ví hoàn cọc',
                              style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                            ),
                            Text(
                              '${user?.walletBalance ?? 0} đ',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cài đặt Chế độ tìm kèo (Find-Match Mode)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radar_rounded, color: AppTheme.accentBlue),
                            SizedBox(width: 10),
                            Text(
                              'Chế độ tìm kèo (Find-Match)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isFindMatch,
                          activeColor: AppTheme.accentBlue,
                          onChanged: _onToggleFindMatch,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tự động nhận thông báo khi có các ca đấu phong trào quanh bạn thiếu người.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                    ),
                    const Divider(height: 24),

                    // Môn thể thao yêu thích
                    const Text(
                      'Bộ môn thể thao yêu thích:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSports.map((sport) {
                        final isSelected = _selectedSports.contains(sport);
                        return FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          selectedColor: AppTheme.pastelBlue,
                          checkmarkColor: AppTheme.accentBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.accentBlue : AppTheme.textDark,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (selected) => _onToggleSport(sport),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút Đăng xuất
            if (!isGuest)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
