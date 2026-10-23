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
              const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Personal stats, skill ratings, and digital wallet.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),

              // User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                              color: Color(0xFF2563EB),
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
                        Icon(Icons.verified, size: 18, color: Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text('Cau Giay District, Hanoi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        '⚡ SportSpot Pro Member',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
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
                  _buildStatCard('28', 'Matches', const Color(0xFF2563EB), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('56h', 'On Court', const Color(0xFF10B981), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('1.4M', 'Split Saved', Colors.amber, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SPORTSPOT WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                        SizedBox(height: 4),
                        Text('320,000 VND', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Instant Top-up via VNPay / Momo simulation'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('+ Top Up', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skill Ratings & Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    _buildSkillTile('Badminton', 'Advanced 4.0 • Verified Coach Match', 0.85, const Color(0xFF2563EB), isDark),
                    const SizedBox(height: 12),
                    _buildSkillTile('Pickleball', 'Intermediate 3.5 • DUPR Sync', 0.70, const Color(0xFF10B981), isDark),
                    const SizedBox(height: 12),
                    _buildSkillTile('Football (Mini)', 'Rank B+ • 14 Goals recorded', 0.78, Colors.amber, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Settings
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242834) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: isFindMatch,
                        onChanged: (val) => setState(() => isFindMatch = val),
                        title: const Text('Open for Quick Matches', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Allow nearby squad hosts to invite you', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeColor: const Color(0xFF2563EB),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: notificationsEnabled,
                        onChanged: (val) => setState(() => notificationsEnabled = val),
                        title: const Text('Match Reminders & Push', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Get notified 2 hours before court time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        activeColor: const Color(0xFF2563EB),
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
                  label: const Text('Preview Splash & Onboarding Deck', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      const SnackBar(content: Text('Logged out of SportSpot session')),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
          color: isDark ? const Color(0xFF242834) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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
          borderRadius: BorderRadius.circular(9999),
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
