import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/maps_launcher.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/confirm_action_sheet.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/match_ui.dart';
import '../../widgets/stacked_avatars.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/bounce_interaction.dart';
import '../../widgets/recruitment_form.dart';
import '../auth/login_screen.dart';
import '../../data/services/database_helper.dart';
import 'match_checkout_screen.dart';
import 'match_discussion_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/venue_repository.dart';
import '../venues/venue_detail_screen.dart';
import '../teams/team_match_screen.dart';

class MatchFeedScreen extends StatefulWidget {
  final Object? repository;
  final bool staff;
  const MatchFeedScreen({super.key, this.repository, this.staff = false});

  @override
  // ignore: no_logic_in_create_state
  State<MatchFeedScreen> createState() {
    return _Module4MatchFeedState();
  }
}

// ignore: unused_element
class _StitchMatchFeedState extends State<MatchFeedScreen> {
  String selectedSport = 'all';
  String selectedLevel = 'all';
  List<SportSpotMatch> matches = List.from(SportSpotMockData.openMatches);

  void _joinMatch(int index) async {
    final current = matches[index];
    if (current.isJoined) {
      final confirmed = await SportSpotConfirmSheet.show(
        context,
        title: 'Xác nhận Rời Trận Đấu',
        message: 'Vị trí của bạn trong đội hình sẽ được mở lại cho người chơi khác.',
        confirmLabel: 'Rời trận',
        cancelLabel: 'Ở lại',
        icon: Icons.exit_to_app_rounded,
        actionType: ConfirmActionType.destructive,
        infoRows: [
          ConfirmInfoRow(label: 'Trận đấu', value: current.venueName),
          ConfirmInfoRow(label: 'Thời gian', value: current.timeDisplay),
        ],
      );
      if (confirmed != true) return;
    }

    setState(() {
      final isNowJoined = !current.isJoined;
      matches[index] = current.copyWith(
        isJoined: isNowJoined,
        spotsTaken: isNowJoined ? current.spotsTaken + 1 : current.spotsTaken - 1,
        spotsNeeded: isNowJoined ? current.spotsNeeded - 1 : current.spotsNeeded + 1,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(matches[index].isJoined
            ? '🎉 Đã giữ chỗ thành công! Bạn đã tham gia đội hình.'
            : 'Đã rời khỏi trận đấu.'),
        backgroundColor: matches[index].isJoined ? const Color(0xFF10B981) : Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHostGameDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181A22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(76),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tạo Trận Đấu Mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mở kèo giao lưu và cùng người chơi xung quanh chia sẻ tiền sân tự động.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Tên trận đấu',
                  hintText: 'VD: Giao lưu cầu lông đôi nam nữ',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Số người cần tìm',
                        hintText: '2',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Chi phí chia sẻ (VND)',
                        hintText: '60,000',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚡ Đã tạo trận đấu! Đã gửi thông báo đến các người chơi gần bạn.'),
                        backgroundColor: Color(0xFF111315),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111315),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Đăng Kèo Trận Đấu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredMatches = matches.where((m) {
      if (selectedSport != 'all' && m.sport != selectedSport) return false;
      if (selectedLevel != 'all' && m.level != selectedLevel) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111216) : const Color(0xFFF7F8FA),
      appBar: SportSpotUnifiedHeader(
        screenName: 'Tìm Kèo Giao Lưu',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _showHostGameDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00A859)),
            tooltip: 'Tạo Kèo Mới',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top utility row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191A1E) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF111315)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bán kính 5 km • Cầu Giấy',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showHostGameDialog,
                    icon: const Icon(Icons.add_circle_rounded, size: 16),
                    label: const Text('Tạo Kèo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111315),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title Header
              const Text('Kèo Giao Lưu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Tham gia các đội hình mở và chia sẻ tiền sân tự động, minh bạch.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Sport Filter Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả môn', Icons.grid_view_rounded),
                    _buildFilterChip('badminton', 'Cầu lông', Icons.sports_tennis_rounded),
                    _buildFilterChip('pickleball', 'Pickleball', Icons.sports_tennis),
                    _buildFilterChip('football', 'Bóng đá', Icons.sports_soccer_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Match Cards List
              if (filteredMatches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.sports_outlined, size: 48, color: Colors.grey.withAlpha(128)),
                        const SizedBox(height: 12),
                        const Text('Không tìm thấy trận đấu phù hợp', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    final originalIndex = matches.indexOf(match);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191A1E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF2E313A) : const Color(0xFFE4E4E0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 76 : 13),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover & Spot status
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                child: Image.network(
                                  match.image,
                                  height: 165,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 165,
                                    color: Colors.grey.shade800,
                                    child: const Center(child: Icon(Icons.sports_tennis, color: Colors.white, size: 48)),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withAlpha(191),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.group, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cần thêm ${match.spotsNeeded} người',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(153),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    match.timeDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 14,
                                right: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.venueName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      match.courtDetails,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Actions and Host Row
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage: NetworkImage(match.hostAvatar),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  match.hostName,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  match.hostRank,
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF111315).withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Tự động chia ${match.splitMultiplier}x',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF111315),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${match.splitPrice ~/ 1000}k đ/người',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF111315),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _joinMatch(originalIndex),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: match.isJoined
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF111315),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          match.isJoined ? 'Đã tham gia! ✓' : 'Tham Gia Kèo',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E212B) : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('💬 Trò chuyện nhóm cùng ${match.hostName} & đội hình'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = selectedSport == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => selectedSport = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF111315)
              : (isDark ? const Color(0xFF242834) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF111315) : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _Module4MatchFeedState extends State<MatchFeedScreen> {
  late final MatchRepository repo = (widget.repository is MatchRepository ? widget.repository as MatchRepository : null) ?? ApiMatchRepository();
  late Future<List<OpenMatch>> result;
  final district = TextEditingController();
  int? sportId;
  String _selectedSkill = 'Tất cả';
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    district.dispose();
    super.dispose();
  }

  void reload() {
    setState(() {
      result = repo.list(
        sportId: sportId,
        district: district.text,
        staff: widget.staff,
      );
    });
  }

  Future<void> createMatch() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || !auth.isAuthenticated) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchCheckoutScreen()),
    );
    if (mounted) reload();
  }

  Future<void> openMatch(OpenMatch match) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          id: match.id,
          repository: repo,
          staff: widget.staff,
        ),
      ),
    );
    if (mounted) reload();
  }

  Widget filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      const Text(
        'BẠN MUỐN CHƠI MÔN GÌ?',
        style: TextStyle(
          fontSize: 10,
          color: MatchColors.muted,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              for (final item in <(int?, String)>[
                (null, 'Tất cả'),
                (1, 'Cầu lông'),
                (2, 'Pickleball'),
                (3, 'Bóng đá mini'),
                (4, 'Bóng rổ'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BounceTap(
                    onTap: () {
                      sportId = item.$1;
                      reload();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: sportId == item.$1 ? MatchColors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sportId == item.$1
                              ? MatchColors.blue
                              : const Color(0xFFD1D5DB),
                          width: 1.2,
                        ),
                        boxShadow: sportId == item.$1
                            ? [
                                BoxShadow(
                                  color: MatchColors.blue.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            matchSportIcon(item.$1 ?? 0),
                            size: 18,
                            color: sportId == item.$1
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            item.$2,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontWeight: sportId == item.$1 ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 12.5,
                              color: sportId == item.$1 ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E4EB), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: MatchColors.muted),
                    SizedBox(width: 5),
                    Text(
                      'Trình độ:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MatchColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              for (final skill in ['Tất cả', 'Cơ bản', 'Trung bình', 'Nâng cao'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: BounceTap(
                    onTap: () {
                      setState(() {
                        _selectedSkill = skill;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSkill == skill ? MatchColors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSkill == skill ? MatchColors.blue : const Color(0xFFD1D5DB),
                          width: 1.2,
                        ),
                        boxShadow: _selectedSkill == skill
                            ? [
                                BoxShadow(
                                  color: MatchColors.blue.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        skill,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 12,
                          fontWeight: _selectedSkill == skill ? FontWeight.w700 : FontWeight.w600,
                          color: _selectedSkill == skill ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: district,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kèo theo quận / khu vực',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 21),
          suffixIcon: IconButton(
            tooltip: 'Tìm khu vực',
            onPressed: reload,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ),
        onSubmitted: (_) => reload(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MatchTheme(
      child: Scaffold(
        appBar: SportSpotUnifiedHeader(
          screenName: widget.staff ? 'Quầy Lễ Tân' : 'Tìm Kèo Giao Lưu',
          showBackButton: widget.staff,
          actions: [
            if (!widget.staff)
              IconButton(
                tooltip: 'Ghép đội bóng',
                icon: const Icon(Icons.sports_soccer),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TeamMatchScreen())),
              ),
            if (!widget.staff && auth.currentUser?.role == 'VenueStaff')
              IconButton(
                tooltip: 'Quầy lễ tân',
                icon: const Icon(Icons.support_agent_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MatchFeedScreen(repository: repo, staff: true),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: widget.staff
            ? null
            : FloatingActionButton.extended(
                backgroundColor: MatchColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Đặt sân & tuyển',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: createMatch,
              ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: FutureBuilder<List<OpenMatch>>(
                future: result,
                builder: (context, snapshot) {
                  final allMatches = snapshot.data ?? [];
                  final matches = allMatches.where((m) {
                    if (_selectedSkill == 'Tất cả') return true;
                    return m.skill.toLowerCase().contains(_selectedSkill.toLowerCase());
                  }).toList();
                  final loading =
                      snapshot.connectionState != ConnectionState.done;
                  return RefreshIndicator(
                    onRefresh: () async {
                      reload();
                      await result;
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MatchHero(
                                  eyebrow: widget.staff
                                      ? 'SPORTSPOT / STAFF DESK'
                                      : 'SPORTSPOT / MATCH DAY',
                                  title: widget.staff
                                      ? 'Kết nối người chơi.\nLấp đầy sân đấu.'
                                      : 'Đủ đồng đội.\nTrọn cuộc chơi.',
                                  subtitle: widget.staff
                                      ? 'Các ca đấu đang cần thêm người tại cụm sân của bạn.'
                                      : 'Tìm kèo hợp gu, gặp đồng đội mới.\nTiền sân chia đều, cuộc vui nhân đôi.',
                                  footer: MatchPill(
                                    widget.staff
                                        ? 'Gán khách trực tiếp tại quầy'
                                        : 'Ghép kèo · Chia tiền minh bạch',
                                    icon: widget.staff
                                        ? Icons.support_agent_rounded
                                        : Icons.verified_outlined,
                                    background: MatchColors.lime,
                                    foreground: MatchColors.navy,
                                  ),
                                ),
                                if (!widget.staff) filters(),
                                const SizedBox(height: 26),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.staff
                                            ? 'Ca đấu cần bổ sung'
                                            : 'Kèo đang chờ bạn',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 21,
                                          letterSpacing: -.5,
                                        ),
                                      ),
                                    ),
                                    if (!loading && !snapshot.hasError)
                                      MatchPill(
                                        '${matches.length} kèo',
                                        background: Colors.white,
                                        foreground: MatchColors.muted,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.staff
                                      ? 'Thu tiền mặt trước khi xác nhận gán khách.'
                                      : 'Chọn trận phù hợp và sẵn sàng ra sân.',
                                  style: const TextStyle(
                                    color: MatchColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        ),
                        if (loading)
                          const SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SkeletonCard(height: 180),
                                  SizedBox(height: 14),
                                  SkeletonCard(height: 180),
                                ],
                              ),
                            ),
                          )
                        else if (snapshot.hasError)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverToBoxAdapter(
                              child: MatchEmptyState(
                                title: 'Chưa thể tải kèo',
                                message:
                                    'Kiểm tra kết nối và thử tải lại danh sách.\n${snapshot.error}',
                                icon: Icons.wifi_off_rounded,
                                onRetry: reload,
                              ),
                            ),
                          )
                        else if (matches.isEmpty)
                          const SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverToBoxAdapter(
                              child: MatchEmptyState(
                                title: 'Chưa có kèo phù hợp',
                                message: 'Thử môn thể thao hoặc khu vực khác.\nBạn cũng có thể đặt sân và tạo kèo của riêng mình.',
                                icon: Icons.sports_tennis_rounded,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList.builder(
                              itemCount:
                                  (matches.length /
                                          (MediaQuery.sizeOf(context).width >=
                                                  800
                                              ? 2
                                              : 1))
                                      .ceil(),
                              itemBuilder: (context, row) {
                                final columns =
                                    MediaQuery.sizeOf(context).width >= 800
                                    ? 2
                                    : 1;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (
                                        var col = 0;
                                        col < columns;
                                        col++
                                      ) ...[
                                        if (col > 0) const SizedBox(width: 16),
                                        Expanded(
                                          child:
                                              row * columns + col <
                                                  matches.length
                                              ? _MatchCard(
                                                  match:
                                                      matches[row * columns +
                                                          col],
                                                  onTap: () => openMatch(
                                                    matches[row * columns +
                                                        col],
                                                  ),
                                                )
                                              : const SizedBox(),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final OpenMatch match;
  final VoidCallback onTap;
  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = match;
    return AppPressable(
      onTap: onTap,
      scaleDown: 0.985,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MatchColors.line),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Badges & Title Overlay
            Stack(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Image.network(
                    m.venueImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: MatchColors.navy,
                      child: Center(
                        child: Icon(
                          matchSportIcon(m.sportId),
                          color: MatchColors.lime,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top header: Sport badge & Slots remaining badge
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(matchSportIcon(m.sportId), color: MatchColors.lime, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  m.sport,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '• ${m.skill}',
                                style: const TextStyle(
                                  color: Color(0xFFD1D5DB),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MatchPill(
                        'Thiếu ${m.remaining} người',
                        icon: Icons.people_alt_outlined,
                        background: const Color(0xFFEDF8D9),
                        foreground: const Color(0xFF3E6511),
                      ),
                    ],
                  ),
                ),
                // Bottom overlay: Title
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 10,
                  child: Text(
                    m.title.isNotEmpty ? m.title : '${m.sport} giao lưu tại ${m.venue}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue name
                  Text(
                    m.venue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Location + Distance chip
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: MatchColors.muted,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${m.court} · ${m.district}',
                          style: const TextStyle(
                            color: MatchColors.muted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF2563EB)),
                            const SizedBox(width: 3),
                            Text(
                              '${m.distanceKm?.toStringAsFixed(1) ?? '1.8'} km',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Schedule box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MatchColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _CardMeta(Icons.calendar_today_outlined, matchDay(m.date)),
                        _CardMeta(Icons.schedule_rounded, (m.slots.isNotEmpty ? m.slots.join(', ') : '18:00 - 20:00')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Cost / person & CTA button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHI PHÍ / NGƯỜI',
                              style: TextStyle(
                                fontSize: 9,
                                color: MatchColors.muted,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              money(m.cost),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: MatchColors.blue,
                                letterSpacing: -.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: MatchColors.navy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem kèo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: MatchColors.lime,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AthleticProgressBar(
                    joined: m.joined,
                    total: m.needed,
                    height: 6,
                  ),
                  const SizedBox(height: 10),
                  // Host avatar & Stacked members
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFEDF3FF),
                        foregroundColor: MatchColors.blue,
                        foregroundImage: (m.hostAvatarUrl != null && m.hostAvatarUrl!.isNotEmpty)
                            ? NetworkImage(m.hostAvatarUrl!)
                            : null,
                        onForegroundImageError: (m.hostAvatarUrl != null && m.hostAvatarUrl!.isNotEmpty)
                            ? (_, _) {}
                            : null,
                        child: Text(
                          m.host.trim().isEmpty ? 'H' : m.host.trim().characters.first.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Host: ${m.host}',
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StackedAvatars(
                        joinedCount: m.joined,
                        totalNeeded: m.needed,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${m.joined}/${m.needed}',
                        style: const TextStyle(
                          color: MatchColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: MatchColors.line),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => MatchDiscussionSheet.show(
                        context,
                        matchId: m.id,
                        matchTitle: '${m.sport} • ${m.venue}',
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: MatchColors.ink),
                      label: Text(
                        'Thảo luận trận đấu',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MatchColors.ink,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8F9FA),
                        foregroundColor: MatchColors.ink,
                        side: const BorderSide(color: Color(0xFFE2E4EB), width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CardMeta(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: MatchColors.blue),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class MatchDetailScreen extends StatefulWidget {
  final int id;
  final MatchRepository repository;
  final bool staff;
  const MatchDetailScreen({
    super.key,
    required this.id,
    required this.repository,
    this.staff = false,
  });
  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late Future<OpenMatch> result;
  bool busy = false;
  bool _hasGuestJoined = false;
  String? _guestTicketQr;
  int _guestWalletBalance = 320000;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    reload();
  }

  Future<void> _checkGuestStatus() async {
    final balance = await DatabaseHelper().getGuestWalletBalance();
    final ticketData = await DatabaseHelper().getGuestJoinedTicket(widget.id);
    if (mounted) {
      setState(() {
        _guestWalletBalance = balance;
        _hasGuestJoined = ticketData != null;
        _guestTicketQr = ticketData != null ? (ticketData['qr_payload'] as String?) : null;
      });
    }
  }

  void reload() {
    setState(() {
      result = widget.repository.detail(widget.id);
    });
  }

  Future<void> _callHost(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _openGoogleMaps(double? lat, double? lng, String address) async {
    await MapsLauncher.openDirections(
      latitude: lat,
      longitude: lng,
      address: address,
    );
  }

  Future<void> _openVenueDetail(BuildContext context, OpenMatch m) async {
    try {
      final venueRepo = VenueRepository();
      final venue = await venueRepo.getVenueDetail(m.venueId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue)),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VenueDetailScreen(
            venue: {
              'id': m.venueId,
              'name': m.venue,
              'address': m.address,
              'images': [m.venueImageUrl],
              'latitude': m.latitude ?? 21.0285,
              'longitude': m.longitude ?? 105.8542,
              'amenities': m.amenities,
            },
          ),
        ),
      );
    }
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('đỗ') || lower.contains('xe') || lower.contains('parking')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('nước') || lower.contains('uống') || lower.contains('tin')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('tắm') || lower.contains('thay đồ')) {
      return Icons.shower_rounded;
    }
    if (lower.contains('điều hòa') || lower.contains('lạnh')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('thuê') || lower.contains('vợt') || lower.contains('bóng')) {
      return Icons.sports_tennis_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Future<void> act(String question, Future<void> Function() action) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || !auth.isAuthenticated) return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.sports_score_rounded,
          color: MatchColors.blue,
          size: 32,
        ),
        title: const Text('Sẵn sàng ra sân?'),
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật kèo thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        reload();
      }
    }
  }

  Future<void> showTicket(OpenMatch m) async {
    setState(() => busy = true);
    try {
      String qr = '';
      if (_guestTicketQr != null && _guestTicketQr!.isNotEmpty) {
        qr = _guestTicketQr!;
      } else {
        final localGuest = await DatabaseHelper().getGuestJoinedTicket(m.id);
        if (localGuest != null && localGuest['qr_payload'] != null) {
          qr = localGuest['qr_payload'] as String;
        } else {
          qr = await widget.repository.ticket(m.id);
        }
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text('Vé tham gia kèo'),
          content: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.venue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                QrImageView(data: qr, size: 240, backgroundColor: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Xuất trình mã QR khi đến sân.',
                  style: TextStyle(fontSize: 12, color: MatchColors.muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _handleJoin(OpenMatch m) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      await act(
        'Thanh toán GIẢ LẬP ${money(m.cost)} và tham gia? Chức năng này dành cho môi trường phát triển.',
        () => widget.repository.join(m.id),
      );
    } else {
      await _showGuestQuickJoinDialog(m);
    }
  }

  Future<void> _showGuestQuickJoinDialog(OpenMatch m) async {
    final balance = await DatabaseHelper().getGuestWalletBalance();
    if (!mounted) return;

    final nameController = TextEditingController(text: 'Khách vãng lai');
    final phoneController = TextEditingController();
    String paymentMethod = balance >= m.cost ? 'wallet' : 'mock';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MatchColors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: MatchColors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tham gia ghép trận', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Dành cho Khách vãng lai (không cần tài khoản)', style: TextStyle(fontSize: 11, color: MatchColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242834) : const Color(0xFFF3F7FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MatchColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.venue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${m.court} · ${matchDay(m.date)} (${(m.slots.isNotEmpty ? m.slots.join(', ') : '18:00 - 20:00')})', style: const TextStyle(fontSize: 11, color: MatchColors.muted)),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền cọc vãng lai:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(money(m.cost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MatchColors.blue)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Họ tên hiển thị:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'VD: Tuấn Vãng Lai',
                            isDense: true,
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên hiển thị' : null,
                        ),
                        const SizedBox(height: 12),
                        const Text('Số điện thoại liên hệ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'VD: 0901234567 (Đội trưởng liên lạc)',
                            isDense: true,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Phương thức thanh toán cọc:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Material(
                          color: paymentMethod == 'wallet' ? const Color(0x0D2563EB) : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: paymentMethod == 'wallet' ? MatchColors.blue : MatchColors.line, width: paymentMethod == 'wallet' ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RadioListTile<String>(
                            value: 'wallet',
                            groupValue: paymentMethod,
                            onChanged: balance >= m.cost ? (val) => setDialogState(() => paymentMethod = val!) : null,
                            title: const Text('Ví tạm trên máy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Số dư: ${money(balance)}${balance < m.cost ? ' (Không đủ số dư)' : ' (Trừ trực tiếp)'}', style: TextStyle(fontSize: 11, color: balance < m.cost ? Colors.red : MatchColors.muted)),
                            secondary: const Icon(Icons.account_balance_wallet_rounded, color: MatchColors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: paymentMethod == 'mock' ? const Color(0x0D2563EB) : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: paymentMethod == 'mock' ? MatchColors.blue : MatchColors.line, width: paymentMethod == 'mock' ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RadioListTile<String>(
                            value: 'mock',
                            groupValue: paymentMethod,
                            onChanged: (val) => setDialogState(() => paymentMethod = val!),
                            title: const Text('Cổng thanh toán giả lập', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Mô phỏng thanh toán cọc tức thì', style: TextStyle(fontSize: 11, color: MatchColors.muted)),
                            secondary: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chính sách vãng lai: Nếu sân bị hủy, tiền cọc hoàn 100% vào Ví tạm trên máy này để dùng cho lượt sau, hoặc gửi email hỗ trợ (support@sportspot.vn) để rút tiền về ngân hàng.',
                                  style: TextStyle(fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Quay lại'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _executeGuestJoin(
                      match: m,
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      useWallet: paymentMethod == 'wallet',
                    );
                  },
                  child: const Text('Xác nhận & Tham gia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeGuestJoin({
    required OpenMatch match,
    required String name,
    required String phone,
    required bool useWallet,
  }) async {
    TicketProvider? ticketProvider;
    try {
      ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    } catch (_) {
      ticketProvider = null;
    }
    setState(() => busy = true);
    try {
      if (useWallet) {
        await DatabaseHelper().deductGuestWalletBalance(match.cost);
      }
      final bookingCode = 'GST-M${match.id}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final qrPayload = 'SPOTPASS|$bookingCode|0|JoinedPlayer|Guest_${name.replaceAll(' ', '_')}|${DateTime.now().millisecondsSinceEpoch}';

      await DatabaseHelper().upsertOfflineBooking({
        'booking_code': bookingCode,
        'venue_id': match.venueId,
        'venue_name': match.venue,
        'sport_name': match.sport,
        'sub_venue_name': match.court,
        'address': match.address,
        'play_date': match.date.toString(),
        'time_slots': match.slots.join(', '),
        'user_role_in_match': 'Khách ghép',
        'total_price': match.cost,
        'deposit_amount': match.cost,
        'status': 'Upcoming',
        'qr_payload': qrPayload,
        'is_checked_in': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await DatabaseHelper().recordGuestJoinedMatch(
        matchId: match.id,
        bookingCode: bookingCode,
        qrPayload: qrPayload,
        guestName: name,
        guestPhone: phone,
      );

      try {
        ticketProvider?.addConfirmedBookingTicket(
          bookingId: match.id + 1000,
          bookingCode: bookingCode,
          venueName: match.venue,
          subVenueName: match.court,
          sportName: match.sport,
          address: match.address,
          playDate: match.date.toString().split(' ').first,
          timeSlots: match.slots,
          courtPrice: match.cost,
          servicesPrice: 0,
          totalPrice: match.cost,
          depositAmount: match.cost,
          remainingBalance: 0,
          qrPayload: qrPayload,
          paymentGateway: useWallet ? 'GuestWallet' : 'MockPayment',
          userRoleInMatch: 'Khách ghép',
        );
      } catch (_) {}

      try {
        await widget.repository.guestJoin(
          match.id,
          name: name,
          phone: phone,
          gateway: useWallet ? 'GuestWallet' : 'MockPayment',
        );
      } catch (_) {
        try {
          await widget.repository.join(match.id);
        } catch (_) {}
      }

      final newBalance = await DatabaseHelper().getGuestWalletBalance();
      if (mounted) {
        setState(() {
          _hasGuestJoined = true;
          _guestTicketQr = qrPayload;
          _guestWalletBalance = newBalance;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $name đã tham gia kèo thành công! Mã QR vé đã lưu trên máy.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        reload();
        await showTicket(match);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tham gia: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _handleLeave(OpenMatch m) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      await act(
        'Rời kèo? Hoàn về ví: trước ≥4 giờ 100%, từ 2–4 giờ 50%, dưới 2 giờ 0%.',
        () => widget.repository.leave(m.id),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rời kèo vãng lai?'),
          content: Text(
            'Bạn có chắc muốn rời kèo đấu này? Tiền cọc ${money(m.cost)} sẽ được hoàn 100% vào Ví tạm trên máy này để bạn tiếp tục tìm các trận khác (hoặc rút về tài khoản ngân hàng qua email).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận hoàn cọc'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
      setState(() => busy = true);
      try {
        await DatabaseHelper().addGuestWalletBalance(m.cost);
        final ticket = await DatabaseHelper().getGuestJoinedTicket(m.id);
        if (ticket != null && ticket['booking_code'] != null) {
          await DatabaseHelper().updateOfflineBookingStatus(
            ticket['booking_code'] as String,
            status: 'Cancelled',
          );
        }
        try {
          await widget.repository.leave(m.id);
        } catch (_) {}
        await DatabaseHelper().removeGuestJoinedMatch(m.id);

        final newBalance = await DatabaseHelper().getGuestWalletBalance();
        if (mounted) {
          setState(() {
            _hasGuestJoined = false;
            _guestTicketQr = null;
            _guestWalletBalance = newBalance;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã rời kèo. Đã hoàn ${money(m.cost)} vào Ví tạm trên máy!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          reload();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }
  }

  void _showGuestWalletInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: MatchColors.blue),
            SizedBox(width: 10),
            Text('Ví tạm trên máy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số dư khả dụng: ${money(_guestWalletBalance)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Dành riêng cho Khách vãng lai: Bạn có thể tham gia các trận ghép trên ứng dụng mà không cần phải đăng ký tài khoản thành viên.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Tự động hoàn tiền: Nếu sân bị chủ sân hủy, hoặc bạn rời kèo đúng hạn, số tiền cọc sẽ lưu lại trong ví này của thiết bị để tiếp tục sử dụng cho các trận sau mà không cần thao tác quét ngân hàng.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Rút về ngân hàng: Nếu không có nhu cầu thi đấu tiếp, vui lòng gửi email về: support@sportspot.vn kèm thông tin mã vé để được hỗ trợ chuyển khoản hoàn tất.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MatchTheme(
    child: Scaffold(
      appBar: SportSpotUnifiedHeader(
        screenName: 'Chi tiết kèo',
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: busy ? null : reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<OpenMatch>(
        future: result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: MatchEmptyState(
                title: 'Chưa thể tải chi tiết',
                message: '${snapshot.error}',
                onRetry: reload,
              ),
            );
          }
          final m = snapshot.data!;
          final user = context.watch<AuthProvider>().currentUser;
          final host = user?.userId == m.hostId;
          final joined = (user != null && m.members.any(
            (mm) => mm.userId == user.userId && mm.type == 'AppUser',
          )) || _hasGuestJoined;
          final open = m.status == 'Open' && m.remaining > 0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  if (!context.watch<AuthProvider>().isAuthenticated)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: MatchColors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: MatchColors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: MatchColors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chế độ Khách vãng lai (Chưa đăng nhập)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MatchColors.blue),
                                ),
                                Text(
                                  'Ví tạm trên máy: ${money(_guestWalletBalance)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showGuestWalletInfo,
                            child: const Text('Chi tiết ví', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  // 1. Top Banner Image with Overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: Image.network(
                            m.venueImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 210,
                              color: MatchColors.navy,
                              child: Center(
                                child: Icon(
                                  matchSportIcon(m.sportId),
                                  size: 56,
                                  color: MatchColors.lime,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.88),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Top Badges
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              MatchPill(
                                matchStatus(m.status),
                                icon: Icons.circle,
                                background: MatchColors.lime,
                                foreground: MatchColors.navy,
                              ),
                              MatchPill(
                                m.skill,
                                icon: Icons.bar_chart_rounded,
                                background: const Color(0xFF315778),
                                foreground: Colors.white,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: Text(
                                  '#${m.id.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Info
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title.isNotEmpty ? m.title : '${m.sport} giao lưu tại ${m.venue}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.venue} • ${m.court}',
                                style: const TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Host Contact Card
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MatchSectionTitle(
                          'Chủ kèo & Liên hệ',
                          'Người mở kèo và trực tiếp điều phối trận đấu.',
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEDF3FF),
                              foregroundColor: MatchColors.blue,
                              foregroundImage: (m.hostAvatarUrl != null && m.hostAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(m.hostAvatarUrl!)
                                  : null,
                              onForegroundImageError: (m.hostAvatarUrl != null && m.hostAvatarUrl!.isNotEmpty)
                                  ? (_, _) {}
                                  : null,
                              child: Text(
                                m.host.trim().isEmpty ? 'H' : m.host.trim().characters.first.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.host,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.hostPhone != null && m.hostPhone!.isNotEmpty
                                        ? 'SĐT/Zalo: ${m.hostPhone}'
                                        : 'Đội trưởng · Chủ kèo',
                                    style: TextStyle(
                                      color: m.hostPhone != null && m.hostPhone!.isNotEmpty
                                          ? MatchColors.blue
                                          : MatchColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (m.hostPhone != null && m.hostPhone!.isNotEmpty)
                              FilledButton.tonalIcon(
                                onPressed: () => _callHost(m.hostPhone!),
                                icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                                label: const Text('Gọi ngay'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Host Note / Ground Rules Card
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MatchSectionTitle(
                          'Ghi chú & Nội quy trận đấu',
                          'Yêu cầu và lưu ý từ chủ kèo để trận đấu vui vẻ, trọn vẹn.',
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.rule_rounded,
                                color: MatchColors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  m.hostNote != null && m.hostNote!.trim().isNotEmpty
                                      ? m.hostNote!
                                      : 'Vui vẻ giao lưu, tôn trọng đối thủ, đến đúng giờ để giữ nhiệt trận đấu!',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Venue Amenities Card
                  if (m.amenityList.isNotEmpty) ...[
                    MatchSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MatchSectionTitle(
                            'Tiện ích sân bãi',
                            'Các tiện nghi sẵn có tại cơ sở phục vụ người chơi.',
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: m.amenityList.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getAmenityIcon(item), size: 15, color: MatchColors.blue),
                                    const SizedBox(width: 6),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Mini Map & Directions Card
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MatchSectionTitle(
                          'Địa điểm & Chỉ đường',
                          'Vị trí sân và chỉ đường nhanh chóng qua Google Maps.',
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: MatchColors.canvas,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: MatchColors.blue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.venue,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${m.court} · ${m.address}',
                                    style: const TextStyle(
                                      color: MatchColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m.distanceKm?.toStringAsFixed(1) ?? '1.8'} km',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openGoogleMaps(
                                  m.latitude,
                                  m.longitude,
                                  m.address.isNotEmpty ? m.address : m.venue,
                                ),
                                icon: const Icon(Icons.directions_rounded, size: 16),
                                label: const Text('Chỉ đường'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: const BorderSide(color: MatchColors.blue),
                                  foregroundColor: MatchColors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _openVenueDetail(context, m),
                                icon: const Icon(Icons.storefront_rounded, size: 16),
                                label: const Text('Chi tiết sân'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Schedule Card
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MatchSectionTitle(
                          'Lịch ra sân',
                          'Lưu lịch, đến đúng giờ và cùng hết mình.',
                        ),
                        _DetailLine(
                          Icons.calendar_today_rounded,
                          'Ngày thi đấu',
                          matchDay(m.date),
                        ),
                        const SizedBox(height: 18),
                        _DetailLine(
                          Icons.schedule_rounded,
                          'Khung giờ',
                          (m.slots.isNotEmpty ? m.slots.join(', ') : '18:00 - 20:00'),
                        ),
                        const SizedBox(height: 18),
                        _DetailLine(
                          Icons.sports_rounded,
                          'Bộ môn thi đấu',
                          '${m.sport} · Trình độ: ${m.skill}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. Team Lineup (Đội hình vãng lai)
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: MatchSectionTitle(
                                'Đội hình vãng lai',
                                'Kết nối qua ứng dụng và tại quầy.',
                              ),
                            ),
                            MatchPill(
                              '${m.joined}/${m.needed}',
                              icon: Icons.people_outline,
                            ),
                          ],
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: m.needed == 0
                                ? 0
                                : (m.joined / m.needed).clamp(0, 1),
                            minHeight: 7,
                            color: MatchColors.blue,
                            backgroundColor: MatchColors.line,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          open
                              ? 'Còn ${m.remaining} vị trí dành cho đồng đội mới'
                              : matchStatus(m.status),
                          style: const TextStyle(
                            fontSize: 12,
                            color: MatchColors.muted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (m.members.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: MatchColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Hãy là người đầu tiên gia nhập đội hình!',
                              style: TextStyle(
                                color: MatchColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        for (final mm in m.members)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFEDF3FF),
                                  foregroundColor: MatchColors.blue,
                                  foregroundImage: (mm.avatarUrl != null && mm.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(mm.avatarUrl!)
                                      : null,
                                  onForegroundImageError: (mm.avatarUrl != null && mm.avatarUrl!.isNotEmpty)
                                      ? (_, _) {}
                                      : null,
                                  child: Text(
                                    mm.name.trim().isEmpty
                                        ? '?'
                                        : mm.name
                                            .trim()
                                            .characters
                                            .first
                                            .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mm.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        mm.type == 'WalkInAtDesk'
                                            ? 'Khách tại quầy'
                                            : 'Tham gia qua ứng dụng',
                                        style: const TextStyle(
                                          color: MatchColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF65A330),
                                  size: 19,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 8. Cost Breakdown & Balance
                  MatchSurface(
                    color: MatchColors.navy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHIA ĐỀU TIỀN SÂN',
                          style: TextStyle(
                            color: MatchColors.lime,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              money(m.cost),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const Text(
                              '/ người',
                              style: TextStyle(
                                color: Color(0xFFB5CEE3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Giá cố định từ tiền sân. Minh bạch cho mọi thành viên.',
                          style: TextStyle(
                            color: Color(0xFFB5CEE3),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (host || widget.staff) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFF35516F)),
                          ),
                          Text(
                            m.balance < 0
                                ? 'Host được nhận lại: ${money(-m.balance)}'
                                : 'Host còn phải đóng: ${money(m.balance)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (joined) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('Xem vé QR của tôi'),
                      onPressed: busy ? null : () => showTicket(m),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (open && !host && !joined && !widget.staff)
                    FilledButton.icon(
                      icon: const Icon(Icons.bolt_rounded),
                      onPressed: busy
                          ? null
                          : () => _handleJoin(m),
                      label: const Text('Tham gia kèo · Thanh toán mock'),
                    ),
                  if (open && host)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.pause_circle_outline_rounded),
                      onPressed: busy
                          ? null
                          : () => act(
                              'Dừng tuyển thêm vãng lai?',
                              () => widget.repository.stop(m.id),
                            ),
                      label: const Text('Dừng tuyển'),
                    ),
                  if (open && widget.staff)
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      onPressed: busy
                          ? null
                          : () => act(
                              'Xác nhận đã thu ${money(m.cost)} tiền mặt từ 1 khách tại quầy?',
                              () => widget.repository.assign(m.id),
                            ),
                      label: const Text('Gán khách vãng lai tại quầy'),
                    ),
                  if (joined)
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _handleLeave(m),
                      child: const Text('Rời kèo'),
                    ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: MatchColors.muted,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Đồng đội thật. Chi phí rõ ràng.',
                        style: TextStyle(
                          fontSize: 11,
                          color: MatchColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailLine(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MatchColors.canvas,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: MatchColors.blue, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: MatchColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}
