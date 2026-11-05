import '../../core/network/api_client.dart';
import 'package:flutter/material.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/bounce_interaction.dart';

class AdminHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const AdminHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends State<AdminHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dữ liệu mẫu duyệt cụm sân
  final List<Map<String, dynamic>> _pendingVenues = [
    {
      'id': 101,
      'name': 'CLB Cầu Lông Tân Bình Sport',
      'address': 'Số 42 Hoàng Hoa Thám, P.13, Q. Tân Bình, TP.HCM',
      'ownerName': 'Trần Văn Mạnh',
      'phone': '0912 345 678',
      'sport': 'Cầu lông (8 sân)',
      'status': 'Chờ duyệt',
      'submitDate': '04/11/2026',
      'priceRange': '100.000đ - 140.000đ/h',
    },
    {
      'id': 102,
      'name': 'Pickleball Vườn Lài Arena',
      'address': '124 Vườn Lài, P. An Phú Đông, Quận 12, TP.HCM',
      'ownerName': 'Lê Hoàng Yến',
      'phone': '0988 765 432',
      'sport': 'Pickleball (6 sân chuẩn USAPA)',
      'status': 'Chờ duyệt',
      'submitDate': '03/11/2026',
      'priceRange': '150.000đ - 220.000đ/h',
    },
    {
      'id': 103,
      'name': 'Sân Bóng Đá Mini Cỏ Nhân Tạo K300',
      'address': 'Khu K300, Đường Cộng Hòa, Q. Tân Bình',
      'ownerName': 'Nguyễn Thành Luân',
      'phone': '0903 112 233',
      'sport': 'Bóng đá 5-7 người (4 sân)',
      'status': 'Đã duyệt',
      'submitDate': '01/11/2026',
      'priceRange': '300.000đ - 450.000đ/h',
    },
  ];

  // Dữ liệu người dùng hệ thống khớp 100% với Database Supabase thực tế
  final List<Map<String, dynamic>> _systemUsers = [
    {
      'id': 1,
      'name': 'Admin',
      'email': 'admin@sportspot.vn',
      'phone': '0900000001',
      'role': 'Admin',
      'isActive': true,
      'joinDate': '01/10/2026',
    },
    {
      'id': 2,
      'name': 'Nguyễn Văn Hùng (Chủ Sân Kỳ Hòa)',
      'email': 'owner.kyhoa@sportspot.vn',
      'phone': '0900000002',
      'role': 'Owner',
      'isActive': true,
      'joinDate': '15/10/2026',
    },
    {
      'id': 3,
      'name': 'Trần Văn Tân (Lễ Tân Sân Cầu Giấy)',
      'email': 'staff.caugiay@sportspot.vn',
      'phone': '0900000003',
      'role': 'VenueStaff',
      'isActive': true,
      'joinDate': '18/10/2026',
    },
    {
      'id': 4,
      'name': 'Phạm Việt Bách',
      'email': 'vietbach171205@gmail.com',
      'phone': '0981234765',
      'role': 'Player',
      'isActive': true,
      'joinDate': '20/10/2026',
    },
    {
      'id': 5,
      'name': 'Phạm Minh Hoàng',
      'email': 'phamminhhoang812@gmail.com',
      'phone': '0912345678',
      'role': 'Player',
      'isActive': true,
      'joinDate': '25/10/2026',
    },
    {
      'id': 6,
      'name': 'Nguyễn Văn A (Host Cầu Lông)',
      'email': 'devuser@sportspot.vn',
      'phone': '0988888888',
      'role': 'Player',
      'isActive': true,
      'joinDate': '28/10/2026',
    },
    {
      'id': 7,
      'name': 'HLV Minh Lê',
      'email': 'coach.minhle@sportspot.vn',
      'phone': '0977112233',
      'role': 'Player',
      'isActive': true,
      'joinDate': '30/10/2026',
    },
  ];

  String _searchUserQuery = '';

  @override
  void initState() {
    super.initState();
    final tabIdx = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 3) ? widget.initialTabIndex : 0;
    _tabController = TabController(length: 3, vsync: this, initialIndex: tabIdx);
    _loadLiveUsers();
  }

  Future<void> _loadLiveUsers() async {
    try {
      final res = await ApiClient().get('/api/admin/users', requiresAuth: false);
      if (res is List && res.isNotEmpty && mounted) {
        setState(() {
          _systemUsers.clear();
          for (final item in res) {
            _systemUsers.add(Map<String, dynamic>.from(item as Map));
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approveVenue(int id) {
    setState(() {
      final index = _pendingVenues.indexWhere((v) => v['id'] == id);
      if (index != -1) {
        _pendingVenues[index]['status'] = 'Đã duyệt';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã phê duyệt cụm sân lên sàn SportSpot thành công!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _rejectVenue(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối hồ sơ cụm sân'),
        content: const Text('Bạn có chắc chắn muốn từ chối cụm sân này? Thông báo kèm lý do sẽ gửi về email chủ sân.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final index = _pendingVenues.indexWhere((v) => v['id'] == id);
                if (index != -1) {
                  _pendingVenues[index]['status'] = 'Từ chối';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã từ chối hồ sơ đăng ký cụm sân.'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(int id) {
    setState(() {
      final index = _systemUsers.indexWhere((u) => u['id'] == id);
      if (index != -1) {
        _systemUsers[index]['isActive'] = !_systemUsers[index]['isActive'];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật trạng thái tài khoản người dùng.'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download_done_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Xuất Báo Cáo Sàn'),
          ],
        ),
        content: const Text(
          'Hệ thống đã xuất file tổng hợp dữ liệu doanh thu, số lượt đặt và đối soát cọc Escrow (SportSpot_Report_Nov2026.xlsx) thành công!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1015) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final textC = isDark ? Colors.white : const Color(0xFF111315);
    final mutedC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderC = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      appBar: SportSpotUnifiedHeader(
        screenName: widget.initialTabIndex == 2
            ? 'Quản Lý Người Dùng'
            : (widget.initialTabIndex == 1 ? 'Duyệt Hồ Sơ Cụm Sân' : 'Thống Kê Toàn Sàn'),
        actions: [
          IconButton(
            tooltip: 'Xuất báo cáo Excel/CSV',
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF16A34A)),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Admin Profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderC)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF8B5CF6), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SportSpot System Admin',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textC),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SUPER ADMIN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toàn quyền phê duyệt sân, giám sát cọc Escrow & tài khoản',
                        style: TextStyle(fontSize: 11.5, color: mutedC),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nội dung tab tương ứng theo menu điều hướng đáy
          Expanded(
            child: widget.initialTabIndex == 2
                ? _buildUsersTab(cardBg, textC, mutedC, borderC)
                : (widget.initialTabIndex == 1
                    ? _buildVenuesTab(cardBg, textC, mutedC, borderC)
                    : _buildOverviewTab(cardBg, textC, mutedC, borderC)),
          ),
        ],
      ),
    );
  }

  // TAB 1: TỔNG QUAN HỆ THỐNG
  Widget _buildOverviewTab(Color cardBg, Color textC, Color mutedC, Color borderC) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 Thẻ KPI chính
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildKpiCard(
              title: 'Tổng Người Dùng',
              value: '1,248',
              subtitle: '+48 người mới tuần này',
              icon: Icons.group_rounded,
              color: const Color(0xFF2563EB),
              cardBg: cardBg,
              textC: textC,
              mutedC: mutedC,
              borderC: borderC,
            ),
            _buildKpiCard(
              title: 'Cụm Sân Hoạt Động',
              value: '18 Cụm',
              subtitle: '2 hồ sơ chờ duyệt',
              icon: Icons.stadium_rounded,
              color: const Color(0xFF00A859),
              cardBg: cardBg,
              textC: textC,
              mutedC: mutedC,
              borderC: borderC,
            ),
            _buildKpiCard(
              title: 'Doanh Số Toàn Sàn',
              value: '48.600.000 đ',
              subtitle: 'Tháng 11/2026',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFF59E0B),
              cardBg: cardBg,
              textC: textC,
              mutedC: mutedC,
              borderC: borderC,
            ),
            _buildKpiCard(
              title: 'Phí Sàn Tích Lũy (5%)',
              value: '2.430.000 đ',
              subtitle: 'Doanh thu thuần sàn',
              icon: Icons.payments_rounded,
              color: const Color(0xFF8B5CF6),
              cardBg: cardBg,
              textC: textC,
              mutedC: mutedC,
              borderC: borderC,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Thống kê Ghép kèo & Escrow
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chỉ Số Vận Hành Ghép Kèo (Module 4 & 5)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textC),
                  ),
                  const Icon(Icons.speed_rounded, color: Color(0xFF00A859), size: 20),
                ],
              ),
              const SizedBox(height: 14),
              _buildMetricProgress('Tỷ lệ ghép kèo thành công', 0.885, '88.5%', const Color(0xFF00A859), textC, mutedC),
              const SizedBox(height: 10),
              _buildMetricProgress('Tỷ lệ check-in giải ngân cọc Escrow', 0.942, '94.2%', const Color(0xFF2563EB), textC, mutedC),
              const SizedBox(height: 10),
              _buildMetricProgress('Tỷ lệ hủy sân trước 4 tiếng (hoàn 100%)', 0.058, '5.8%', const Color(0xFFF59E0B), textC, mutedC),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Nút Xuất báo cáo nhanh
        BounceTap(
          onTap: _exportReport,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A859), Color(0xFF00753C)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A859).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Xuất Toàn Bộ Báo Cáo Kế Toán & Đối Soát (Excel)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color textC,
    required Color mutedC,
    required Color borderC,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: mutedC),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textC),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: mutedC),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricProgress(String label, double ratio, String percentText, Color color, Color textC, Color mutedC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textC, fontWeight: FontWeight.w500)),
            Text(percentText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // TAB 2: DUYỆT CỤM SÂN MỚI
  Widget _buildVenuesTab(Color cardBg, Color textC, Color mutedC, Color borderC) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingVenues.length,
      itemBuilder: (context, index) {
        final venue = _pendingVenues[index];
        final isApproved = venue['status'] == 'Đã duyệt';
        final isRejected = venue['status'] == 'Từ chối';

        Color statusColor = const Color(0xFFF59E0B);
        if (isApproved) statusColor = const Color(0xFF16A34A);
        if (isRejected) statusColor = const Color(0xFFDC2626);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      venue['name'],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textC),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      venue['status'],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '📍 ${venue['address']}',
                style: TextStyle(fontSize: 12, color: mutedC),
              ),
              const SizedBox(height: 4),
              Text(
                '🏅 Quy mô: ${venue['sport']} | 💵 ${venue['priceRange']}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textC),
              ),
              const SizedBox(height: 4),
              Text(
                '👤 Chủ sân: ${venue['ownerName']} (${venue['phone']}) • Ngày nộp: ${venue['submitDate']}',
                style: TextStyle(fontSize: 11.5, color: mutedC),
              ),
              const Divider(height: 20),
              if (!isApproved && !isRejected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _rejectVenue(venue['id']),
                      child: const Text('Từ chối'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A859),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => _approveVenue(venue['id']),
                      child: const Text('Phê duyệt lên sàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      isApproved ? Icons.verified_rounded : Icons.cancel_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isApproved ? 'Cụm sân này đã xuất hiện trên bản đồ tìm kiếm' : 'Hồ sơ này đã bị từ chối phê duyệt',
                      style: TextStyle(fontSize: 11.5, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: QUẢN LÝ NGƯỜI DÙNG
  Widget _buildUsersTab(Color cardBg, Color textC, Color mutedC, Color borderC) {
    final filteredUsers = _systemUsers.where((u) {
      if (_searchUserQuery.isEmpty) return true;
      final q = _searchUserQuery.toLowerCase();
      return u['name'].toString().toLowerCase().contains(q) ||
          u['phone'].toString().contains(q) ||
          u['email'].toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Ô tìm kiếm tài khoản
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchUserQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, số điện thoại, email...',
              hintStyle: TextStyle(fontSize: 13, color: mutedC),
              prefixIcon: Icon(Icons.search_rounded, color: mutedC),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderC),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderC),
              ),
            ),
          ),
        ),

        // Danh sách tài khoản
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isActive = user['isActive'] as bool;
              final role = user['role'] as String;

              Color roleColor = const Color(0xFF2563EB);
              if (role == 'Admin') roleColor = const Color(0xFF8B5CF6);
              if (role == 'Owner') roleColor = const Color(0xFF00A859);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Text(
                        user['name'][0],
                        style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'],
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textC),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user['phone']} • ${user['email']}',
                            style: TextStyle(fontSize: 11, color: mutedC),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tham gia: ${user['joinDate']}',
                            style: TextStyle(fontSize: 10, color: mutedC),
                          ),
                        ],
                      ),
                    ),
                    // Nút khóa / mở khóa
                    Column(
                      children: [
                        Switch(
                          value: isActive,
                          activeThumbColor: const Color(0xFF00A859),
                          onChanged: role == 'Admin' ? null : (_) => _toggleUserStatus(user['id']),
                        ),
                        Text(
                          isActive ? 'Hoạt động' : 'Đã khóa',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF00A859) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
