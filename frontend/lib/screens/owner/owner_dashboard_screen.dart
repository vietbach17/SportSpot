import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_header.dart';
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
  int _selectedDayIndex = 6;

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
      appBar: SportSpotUnifiedHeader(
        screenName: 'Bảng Điều Khiển Chủ Sân',
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
    if (daily.isEmpty) return const SizedBox.shrink();

    final maxRevenue = daily.isNotEmpty
        ? daily.map((d) => d.revenue).reduce((a, b) => a > b ? a : b)
        : 1;
    final maxVal = maxRevenue > 0 ? maxRevenue : 1;

    final selectedIndex = (_selectedDayIndex >= 0 && _selectedDayIndex < daily.length)
        ? _selectedDayIndex
        : (daily.length - 1);
    final selectedDay = daily[selectedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                'Chạm vào cột ngày để xem chi tiết',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: mutedColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A859).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Đang chọn: ${selectedDay.dayOfWeek} (${selectedDay.date})',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A859)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(daily.length, (idx) {
              final d = daily[idx];
              final isSelected = idx == selectedIndex;
              final heightRatio = (d.revenue / maxVal).clamp(0.12, 1.0);
              final barHeight = 75.0 * heightRatio;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = idx;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00A859).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF00A859), width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.revenue >= 1000000
                            ? '${(d.revenue / 1000000).toStringAsFixed(1)}M'
                            : (d.revenue > 0 ? '${(d.revenue / 1000).round()}k' : '0k'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF00A859) : const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: isSelected ? 26 : 22,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [const Color(0xFF00E676), const Color(0xFF00A859)]
                                : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00A859).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.dayOfWeek,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? const Color(0xFF00A859) : textColor,
                        ),
                      ),
                      Text(
                        d.date,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? textColor : mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Interactive detail card for the selected day
          InkWell(
            onTap: () => _showDayDetailSheet(context, selectedDay),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A859).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A859).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF00A859), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDay.dayOfWeek} (${selectedDay.date})',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            Text(
                              _formatCurrency(selectedDay.revenue),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00A859)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedDay.revenue > 0
                              ? '${selectedDay.bookingCount} lượt đặt sân · Đã giải ngân thành công'
                              : 'Chưa có đơn đặt sân trong ngày này (Chạm để xem chi tiết)',
                          style: TextStyle(fontSize: 11.5, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF00A859)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetailSheet(BuildContext context, DailyRevenueModel day) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final textC = isDark ? Colors.white : const Color(0xFF111315);
    final mutedC = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderC = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedC.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A859).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF00A859), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Báo Cáo: ${day.dayOfWeek} (${day.date})',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textC),
                          ),
                          Text(
                            'Chi tiết doanh số và đơn đặt trong ngày',
                            style: TextStyle(fontSize: 12, color: mutedC),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22242D) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng doanh thu thực nhận:', style: TextStyle(fontSize: 13, color: mutedC)),
                        Text(
                          _formatCurrency(day.revenue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF00A859)),
                        ),
                      ],
                    ),
                    Divider(height: 20, color: borderC),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số lượt đặt sân:', style: TextStyle(fontSize: 13, color: mutedC)),
                        Text(
                          '${day.bookingCount} đơn',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textC),
                        ),
                      ],
                    ),
                    Divider(height: 20, color: borderC),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trạng thái cọc Escrow:', style: TextStyle(fontSize: 13, color: mutedC)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: day.revenue > 0
                                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                : const Color(0xFF6B7280).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            day.revenue > 0 ? 'Đã giải ngân' : 'Không có giao dịch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: day.revenue > 0 ? const Color(0xFF16A34A) : mutedC,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A859),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
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
