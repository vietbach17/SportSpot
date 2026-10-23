import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _activeTrendingSport = 'Pickleball';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A22) : const Color(0xFFFAF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xE61E212B) : Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sports_tennis_rounded,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sport',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF2563EB),
                          ),
                        ),
                        const Text(
                          'Spot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Realtime badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xCC1E212B) : Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '1,420 sân đang mở',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Paddle & Athlete Visual Frame
              SizedBox(
                height: 360,
                width: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Paddle Card Outer
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [const Color(0xFF2C303F), const Color(0xFF181A22)]
                              : [const Color(0xFFCCE4F7), Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDLvh14dW4buaYmSxSIL55ZTGNm88oVR4b1RRNDe6s5w8VNO-QAbrkqhHgfB5Myul8L9t0mtB-RUT3tiLA5qeq26kVO9Oy7ETVMD97o-6mwvBqHDURVb37v6j-DQSytGfq5M4jU4H7R4iLNGTiu-dNl1gL-s05QaEa9j7PYO_EvWULu2PfAIpx04Vu9teMhOiR1wyxk05_FbTehsd04pWk0Pjj0FllP79ChiQOPPbWJ5aMzwWcfFAreQw',
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xB3181A22),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Rating Badge
                    Positioned(
                      top: 18,
                      right: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('4.9', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(' (3.2k)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),

                    // Fast Match Badge
                    Positioned(
                      bottom: 18,
                      left: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('FAST MATCH', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trending Sports Tape
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Pickleball', 'Badminton', 'Padel', 'Mini Football'].map((sport) {
                    final isSelected = _activeTrendingSport == sport;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTrendingSport = sport),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF242834) : Colors.white),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sport.contains('Football') ? Icons.sports_soccer_rounded : Icons.sports_tennis_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sport,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Card Action Deck
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222632) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'SOCIAL SPORTS CLUB',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        children: const [
                          TextSpan(text: 'Find Court.\n'),
                          TextSpan(text: 'Split Cost.\n', style: TextStyle(color: Color(0xFF2563EB))),
                          TextSpan(text: 'Play Sport.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đặt sân tức thì, tự động chia tiền đội bóng và vé vào cửa tự động QR tới hơn 1,400+ sân thể thao.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Primary Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onLoginRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đăng nhập / Đăng ký',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _onExploreAsGuest,
                        child: Text(
                          'Khám phá ngay (Khách vãng lai) ↗',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
