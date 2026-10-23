import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/match_ui.dart';
import '../../widgets/recruitment_form.dart';
import '../auth/phone_input_screen.dart';
import 'match_checkout_screen.dart';

class MatchFeedScreen extends StatefulWidget {
  final Object? repository;
  final bool staff;
  const MatchFeedScreen({super.key, this.repository, this.staff = false});

  @override
  State<MatchFeedScreen> createState() {
    if (repository != null || staff) {
      return _Module4MatchFeedState();
    }
    return _StitchMatchFeedState();
  }
}

class _StitchMatchFeedState extends State<MatchFeedScreen> {
  String selectedSport = 'all';
  String selectedLevel = 'all';
  List<SportSpotMatch> matches = List.from(SportSpotMockData.openMatches);

  void _joinMatch(int index) {
    setState(() {
      final current = matches[index];
      final isNowJoined = !current.isJoined;
      matches[index] = current.copyWith(
        isJoined: isNowJoined,
        spotsTaken: isNowJoined ? current.spotsTaken + 1 : current.spotsTaken - 1,
        spotsNeeded: isNowJoined ? current.spotsNeeded - 1 : current.spotsNeeded + 1,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(matches[index].isJoined
            ? '🎉 Match slot reserved! You are in squad.'
            : 'Left the match.'),
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
                'Host a Match',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create an open game slot and let nearby players auto-split court fees.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Match Title',
                  hintText: 'e.g. Badminton Doubles Friendly',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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
                        labelText: 'Slots Needed',
                        hintText: '2',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                        labelText: 'Split Fee (VND)',
                        hintText: '60,000',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF242834) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                        content: Text('⚡ Match created! Nearby players notified.'),
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Publish Match', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                        color: isDark ? const Color(0xFF242834) : Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Within 5 km • Cau Giay',
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
                    label: const Text('Host Game', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title Header
              const Text('Open Matches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Join open player slots and auto-split court fees effortlessly.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Sport Filter Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Sports', Icons.grid_view_rounded),
                    _buildFilterChip('badminton', 'Badminton', Icons.sports_tennis_rounded),
                    _buildFilterChip('pickleball', 'Pickleball', Icons.sports_tennis),
                    _buildFilterChip('football', 'Football', Icons.sports_soccer_rounded),
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
                        const Text('No matches found for this filter', style: TextStyle(color: Colors.grey)),
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
                        color: isDark ? const Color(0xFF242834) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.group, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Needs ${match.spotsNeeded} players',
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
                                    borderRadius: BorderRadius.circular(9999),
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
                                            color: const Color(0xFF2563EB).withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Auto-split ${match.splitMultiplier}x',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${match.splitPrice ~/ 1000}k VND/person',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF2563EB),
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
                                              : const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          match.isJoined ? 'Joined! ✓' : 'Join Match',
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
                                              content: Text('💬 Squad Chat with ${match.hostName} & group'),
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
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF242834) : Colors.white),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white12 : Colors.black12),
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
        MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
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
                child: ChoiceChip(
                  showCheckmark: false,
                  selected: sportId == item.$1,
                  avatar: Icon(
                    matchSportIcon(item.$1 ?? 0),
                    size: 18,
                    color: sportId == item.$1
                        ? Colors.white
                        : MatchColors.muted,
                  ),
                  label: Text(item.$2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: sportId == item.$1 ? Colors.white : MatchColors.ink,
                  ),
                  selectedColor: MatchColors.blue,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: sportId == item.$1
                        ? MatchColors.blue
                        : MatchColors.line,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  onSelected: (_) {
                    sportId = item.$1;
                    reload();
                  },
                ),
              ),
          ],
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
        appBar: AppBar(
          title: SportSpotBrandTitle(
            title: widget.staff ? 'Quầy lễ tân' : 'SportSpot',
          ),
          actions: [
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
            const SizedBox(width: 8),
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
                  final matches = snapshot.data ?? [];
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
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: MatchColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF3FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      matchSportIcon(m.sportId),
                      color: MatchColors.blue,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.sport,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.skill,
                          style: const TextStyle(
                            color: MatchColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MatchPill(
                    'Thiếu ${m.remaining} người',
                    icon: Icons.people_alt_outlined,
                    background: const Color(0xFFEDF8D9),
                    foreground: const Color(0xFF3E6511),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                m.venue,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: MatchColors.muted,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${m.court} · ${m.district}',
                      style: const TextStyle(
                        color: MatchColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MatchColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _CardMeta(Icons.calendar_today_outlined, matchDay(m.date)),
                    _CardMeta(Icons.schedule_rounded, m.slots.join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 17),
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
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(m.cost),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MatchColors.blue,
                            letterSpacing: -.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: MatchColors.navy,
                      borderRadius: BorderRadius.circular(12),
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
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: MatchColors.lime,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.needed == 0 ? 0 : (m.joined / m.needed).clamp(0, 1),
                  minHeight: 4,
                  color: MatchColors.blue,
                  backgroundColor: MatchColors.line,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '${m.joined}/${m.needed} vãng lai đã tham gia · Host: ${m.host}',
                style: const TextStyle(color: MatchColors.muted, fontSize: 11),
              ),
            ],
          ),
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
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    setState(() {
      result = widget.repository.detail(widget.id);
    });
  }

  Future<void> act(String question, Future<void> Function() action) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
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
      final qr = await widget.repository.ticket(m.id);
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

  @override
  Widget build(BuildContext context) => MatchTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết kèo'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: busy ? null : reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
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
          final joined = m.members.any(
            (mm) => mm.userId == user?.userId && mm.type == 'AppUser',
          );
          final open = m.status == 'Open' && m.remaining > 0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  MatchHero(
                    eyebrow:
                        '${m.sport.toUpperCase()} / MATCH #${m.id.toString().padLeft(3, '0')}',
                    title: m.venue,
                    subtitle: '${m.court} · ${m.address}',
                    footer: Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          m.slots.join(', '),
                        ),
                        const SizedBox(height: 18),
                        _DetailLine(
                          Icons.person_outline_rounded,
                          'Đội trưởng',
                          m.host,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                  foregroundImage:
                                      mm.avatarUrl == null ||
                                          mm.avatarUrl!.isEmpty
                                      ? null
                                      : NetworkImage(mm.avatarUrl!),
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
                          : () => act(
                              'Thanh toán GIẢ LẬP ${money(m.cost)} và tham gia? Chức năng này dành cho môi trường phát triển.',
                              () => widget.repository.join(m.id),
                            ),
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
                          : () => act(
                              'Rời kèo? Hoàn về ví: trước ≥4 giờ 100%, từ 2–4 giờ 50%, dưới 2 giờ 0%.',
                              () => widget.repository.leave(m.id),
                            ),
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
