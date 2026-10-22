import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/time_slot_grid_widget.dart';
import 'booking_checkout_screen.dart';

class CourtSlotsScreen extends StatefulWidget {
  final int venueId;

  const CourtSlotsScreen({
    super.key,
    this.venueId = 1,
  });

  @override
  State<CourtSlotsScreen> createState() => _CourtSlotsScreenState();
}

class _CourtSlotsScreenState extends State<CourtSlotsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadVenue(widget.venueId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.venueDetail?.name ?? 'Đặt Khung Giờ',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới khung giờ',
            onPressed: () => provider.loadSlotsForCurrentDate(),
          ),
        ],
      ),
      body: provider.isLoading && provider.venueDetail == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadSlotsForCurrentDate(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVenueHeader(provider),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    _buildSubVenuesSelector(provider),
                    const SizedBox(height: 8),
                    _buildDateSection(provider),
                    const SizedBox(height: 12),
                    _buildLegend(),
                    const SizedBox(height: 8),
                    _buildSlotGrid(provider),
                    const SizedBox(height: 120), // Bottom padding for sticky bar
                  ],
                ),
              ),
            ),
      bottomSheet: _buildBottomSummary(context, provider),
    );
  }

  Widget _buildVenueHeader(BookingProvider provider) {
    final venue = provider.venueDetail;
    if (venue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  venue.sportName,
                  style: const TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${venue.rating}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            venue.name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${venue.address}, ${venue.district}',
                  style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubVenuesSelector(BookingProvider provider) {
    if (provider.subVenues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Chọn sân đấu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: provider.subVenues.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sub = provider.subVenues[index];
              final isSelected = provider.selectedSubVenue?.id == sub.id;

              return ChoiceChip(
                label: Text(sub.name),
                selected: isSelected,
                selectedColor: AppTheme.accentBlue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textDark,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentBlue : const Color(0xFFE0E0E0),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    provider.selectSubVenue(sub);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(BookingProvider provider) {
    if (provider.dateRange.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.accentBlue),
              SizedBox(width: 6),
              Text(
                'Chọn ngày thi đấu (7 ngày tới)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        DateSelectorWidget(
          dateRange: provider.dateRange,
          selectedDate: provider.selectedDate,
          onDateSelected: (date) => provider.selectDate(date),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem(const Color(0xFF4CAF50), 'Trống'),
            _legendItem(AppTheme.accentBlue, 'Đang chọn'),
            _legendItem(const Color(0xFFBDBDBD), 'Đã kín / Qua'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildSlotGrid(BookingProvider provider) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return TimeSlotGridWidget(
      slots: provider.slots,
      selectedSlots: provider.selectedSlots,
      onSlotToggled: (slot) {
        final error = provider.toggleSlot(slot);
        if (error != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.redAccent.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildBottomSummary(BuildContext context, BookingProvider provider) {
    final count = provider.selectedSlots.length;
    final hasSelection = count > 0;
    final courtTotal = provider.courtPrice;

    String slotSummaryText = 'Vui lòng chọn slot giờ (tối đa 3h)';
    if (hasSelection) {
      final first = provider.selectedSlots.first.startTime;
      final last = provider.selectedSlots.last.endTime;
      slotSummaryText = '$count slot ($first - $last)';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slotSummaryText,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textGray),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSelection ? currencyFormat.format(courtTotal) : '0 đ',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: hasSelection
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingCheckoutScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                disabledBackgroundColor: AppTheme.textGray.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiếp tục',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
