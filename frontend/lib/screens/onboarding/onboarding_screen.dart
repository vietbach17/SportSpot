import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/token_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_input_screen.dart';
import '../main/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Đặt Sân Nhanh Chóng',
      'subtitle': 'Khám phá và giữ chỗ sân Cầu lông, Pickleball, Bóng đá mini, Bóng rổ chỉ trong 30 giây mà không lo trùng lịch.',
      'icon': Icons.sports_tennis_rounded,
    },
    {
      'title': 'Kèo Mở & Tuyển Vãng Lai',
      'subtitle': 'Thiếu người cùng chơi? Đăng tuyển vãng lai với cơ chế tự động chia tiền sòng phẳng và minh bạch.',
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Vé Ngoại Tuyến & Check-in QR',
      'subtitle': 'Không cần mạng 4G/Wi-Fi! Vé điện tử và mã QR của bạn luôn được lưu an toàn trên máy để nhận sân.',
      'icon': Icons.qr_code_scanner_rounded,
    },
  ];

  void _onExploreAsGuest() async {
    await TokenService.setOnboardingSeen();
    if (!mounted) return;
    context.read<AuthProvider>().setGuestMode();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _onLoginRegister() async {
    await TokenService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Nút Bỏ qua ở góc phải
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _onExploreAsGuest,
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView 3 slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon minh họa lớn với nền pastel
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.pastelBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentBlue.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 68,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Tiêu đề
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mô tả
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textGray,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator chấm tròn
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.accentBlue : AppTheme.pastelBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 2 Nút bấm hành động
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onLoginRegister,
                      child: const Text('Đăng nhập / Đăng ký'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _onExploreAsGuest,
                      child: const Text('Khám phá ngay (Khách vãng lai)'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
