import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/owner_dashboard_model.dart';
import '../../data/repositories/owner_repository.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final int? venueId;
  final IOwnerRepository? repository;

  const OwnerDashboardScreen({
    super.key,
    this.venueId,
    this.repository,
  });

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final IOwnerRepository _repository;
  OwnerDashboardModel? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiOwnerRepository();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.getDashboard(venueId: widget.venueId ?? 1);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSubVenue(SubVenueManagementModel subVenue) async {
    final nextState = !subVenue.isActive;
    setState(() {
      if (_dashboardData != null) {
        final updated = _dashboardData!.subVenues.map((sv) {
          return sv.id == subVenue.id ? sv.copyWith(isActive: nextState) : sv;
        }).toList();
        _dashboardData = OwnerDashboardModel(
          venueId: _dashboardData!.venueId,
          venueName: _dashboardData!.venueName,
          venueAddress: _dashboardData!.venueAddress,
          sportName: _dashboardData!.sportName,
          totalBookings: _dashboardData!.totalBookings,
          totalRevenue: _dashboardData!.totalRevenue,
          escrowHoldingAmount: _dashboardData!.escrowHoldingAmount,
          occupancyRatePercentage: _dashboardData!.occupancyRatePercentage,
          activeSubVenuesCount: updated.where((s) => s.isActive).length,
          totalSubVenuesCount: updated.length,
          dailyRevenues: _dashboardData!.dailyRevenues,
          recentBookings: _dashboardData!.recentBookings,
          subVenues: updated,
        );
      }
    });

    try {
      await _repository.toggleSubVenueStatus(subVenue.id, isActive: nextState);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: nextState ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          content: Text(
            nextState
                ? 'Đã mở nhận khách cho "${subVenue.name}".'
                : 'Đã tạm dừng hoạt động "${subVenue.name}" để bảo trì.',
          ),
        ),
      );
    } catch (e) {
      _loadDashboard();
    }
  }

  static String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return '${buffer.toString().split('').reversed.join()} đ';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const cardColor = Colors.white;
    const textColor = Color(0xFF0F172A);
    const mutedColor = Color(0xFF64748B);
    final borderColor = Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Bảng Điều Khiển Chủ Sân',
          style: TextStyle(
            fontFamily: AppTheme.headingFont,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Làm mới số liệu',
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Lỗi: $_errorMessage'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDashboard, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _buildDashboardContent(cardColor, borderColor, textColor, mutedColor),
    );
  }

  Widget _buildDashboardContent(Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    final data = _dashboardData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Venue info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${data.sportName.toUpperCase()} • CHỦ SÂN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
                        const SizedBox(width: 4),
                        Text(
                          '${data.activeSubVenuesCount}/${data.totalSubVenuesCount} sân mở',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.venueName,
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.venueAddress,
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 4 Metrics Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Doanh thu thực tế',
                  value: _formatCurrency(data.totalRevenue),
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF16A34A),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Cọc Escrow tạm giữ',
                  value: _formatCurrency(data.escrowHoldingAmount),
                  icon: Icons.lock_clock_rounded,
                  iconColor: const Color(0xFFD97706),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Tổng lượt đặt sân',
                  value: '${data.totalBookings} đơn',
                  icon: Icons.confirmation_number_rounded,
                  iconColor: const Color(0xFF2563EB),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Tỷ lệ lấp đầy hôm nay',
                  value: '${data.occupancyRatePercentage}%',
                  icon: Icons.pie_chart_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 3. 7-Day Revenue Trend
          Text(
            'DOANH THU 7 NGÀY GẦN NHẤT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 0.2),
          ),
          const SizedBox(height: 10),
          _buildDailyRevenueBars(data.dailyRevenues, cardColor, borderColor, textColor, mutedColor),
          const SizedBox(height: 22),

          // 4. SubVenue Management
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUẢN LÝ SÂN CON (${data.subVenues.length})',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 0.2),
              ),
              Text(
                'Bật/Tắt bảo trì tức thì',
                style: TextStyle(fontSize: 11.5, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.subVenues.map((sv) => _buildSubVenueCard(sv, cardColor, borderColor, textColor, mutedColor)),
          const SizedBox(height: 22),

          // 5. Recent Bookings
          Text(
            'ĐƠN ĐẶT SÂN GẦN ĐÂY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 0.2),
          ),
          const SizedBox(height: 10),
          if (data.recentBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                'Chưa có đơn đặt sân nào.',
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
            )
          else
            ...data.recentBookings.map((b) => _buildRecentBookingCard(b, cardColor, borderColor, textColor, mutedColor)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: mutedColor),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRevenueBars(
    List<DailyRevenueModel> daily,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    final maxRevenue = daily.isNotEmpty
        ? daily.map((d) => d.revenue).reduce((a, b) => a > b ? a : b)
        : 1;
    final maxVal = maxRevenue > 0 ? maxRevenue : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: daily.map((d) {
          final heightRatio = (d.revenue / maxVal).clamp(0.08, 1.0);
          final barHeight = 85.0 * heightRatio;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.revenue >= 1000000 ? '${(d.revenue / 1000000).toStringAsFixed(1)}M' : '${(d.revenue / 1000).round()}k',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.dayOfWeek,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
              ),
              Text(
                d.date,
                style: TextStyle(fontSize: 9.5, color: mutedColor),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubVenueCard(
    SubVenueManagementModel sv,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sv.isActive ? borderColor : Colors.orange.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                sv.isActive ? Icons.sports_tennis_rounded : Icons.handyman_rounded,
                size: 20,
                color: sv.isActive ? const Color(0xFF16A34A) : Colors.orange,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sv.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  Text(
                    sv.isActive
                        ? '${sv.bookedSlotsToday}/${sv.totalSlotsToday} slots hôm nay đã đặt'
                        : 'Đang tạm đóng để bảo trì',
                    style: TextStyle(
                      fontSize: 12,
                      color: sv.isActive ? mutedColor : Colors.orange.shade700,
                      fontWeight: sv.isActive ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: sv.isActive,
            activeTrackColor: const Color(0xFF16A34A),
            onChanged: (_) => _toggleSubVenue(sv),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCard(
    OwnerBookingModel b,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusFg = const Color(0xFFD97706);
    String statusLabel = 'ESCROW TẠM GIỮ';

    if (b.status == 'Completed' || b.escrowStatus == 'Settled') {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF16A34A);
      statusLabel = 'ĐÃ CHECK-IN (QUYẾT TOÁN)';
    } else if (b.status == 'Cancelled') {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFDC2626);
      statusLabel = 'ĐÃ HỦY (HOÀN TIỀN)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.bookingCode,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${b.customerName} • ${b.customerPhone.isNotEmpty ? b.customerPhone : "090xxxxxxx"}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            '${b.subVenueName} • Ngày ${b.playDate} (${b.timeSlots.join(', ')})',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng: ${_formatCurrency(b.totalPrice)}',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textColor),
              ),
              Text(
                'Cọc: ${_formatCurrency(b.depositAmount)}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
