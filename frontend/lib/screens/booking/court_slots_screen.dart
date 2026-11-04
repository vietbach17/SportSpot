import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/match_ui.dart';
import '../../widgets/bounce_interaction.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/time_slot_grid_widget.dart';
import 'booking_checkout_screen.dart';
import '../../widgets/brand_header.dart';

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

    return MatchTheme(
      child: Scaffold(
        appBar: SportSpotUnifiedHeader(
          screenName: provider.venueDetail?.name ?? 'Đặt Khung Giờ',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới khung giờ',
              onPressed: () => provider.loadSlotsForCurrentDate(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomSummary(context, provider),
        body: provider.isLoading && provider.venueDetail == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.loadSlotsForCurrentDate(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _buildVenueHeader(provider),
                        const SizedBox(height: 16),
                        _buildSubVenuesSelector(provider),
                        const SizedBox(height: 16),
                        _buildDateAndSlotsSection(provider),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVenueHeader(BookingProvider provider) {
    final venue = provider.venueDetail;
    if (venue == null) return const SizedBox.shrink();

    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MatchPill(
                venue.sportName,
                icon: matchSportIcon(venue.sportId),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${venue.rating}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: MatchColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            venue.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: MatchColors.ink,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: MatchColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${venue.address}, ${venue.district}',
                  style: const TextStyle(
                    color: MatchColors.muted,
                    fontSize: 13,
                  ),
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

    return MatchSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MatchSectionTitle(
            'Chọn sân đấu',
            'Chọn sân cụ thể bạn muốn đặt lịch trong cụm sân này.',
            step: '01',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.subVenues.map((sub) {
              final isSelected = provider.selectedSubVenue?.id == sub.id;
              return BounceTap(
                onTap: () => provider.selectSubVenue(sub),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? MatchColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? MatchColors.blue : MatchColors.line,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
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
                    sub.name,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      color: isSelected ? Colors.white : MatchColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MatchColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111315).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF111315)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('C1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111315))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.selectedSubVenue?.name ?? 'Sân thi đấu tiêu chuẩn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MatchColors.ink), overflow: TextOverflow.ellipsis, maxLines: 1),
                            const Text('Tiêu chuẩn BWF Quốc tế • Thảm giảm chấn cao cấp', style: TextStyle(fontSize: 11, color: Color(0xFF00A859), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A859).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00A859)),
                  ),
                  child: const Text('SÂN KHẢ DỤNG', style: TextStyle(color: Color(0xFF00A859), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndSlotsSection(BookingProvider provider) {
    return MatchSurface(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: MatchSectionTitle(
              'Thời gian & Khung giờ',
              'Chọn ngày thi đấu và tối đa 3 khung giờ liên tiếp.',
              step: '02',
            ),
          ),
          if (provider.dateRange.isNotEmpty)
            DateSelectorWidget(
              dateRange: provider.dateRange,
              selectedDate: provider.selectedDate,
              onDateSelected: (date) => provider.selectDate(date),
            ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _SlotLegend('Còn trống', Colors.white, border: true),
                _SlotLegend('Đang chọn', MatchColors.blue),
                _SlotLegend('Đã kín / đã qua', Color(0xFFF0F3F7)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TimeSlotGridWidget(
              slots: provider.slots,
              selectedSlots: provider.selectedSlots,
              onSlotToggled: (slot) {
                final error = provider.toggleSlot(slot);
                if (error != null) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, BookingProvider provider) {
    final count = provider.selectedSlots.length;
    final hasSelection = count > 0;
    final courtTotal = provider.courtPrice;

    String slotSummaryText = 'Chọn tối đa 3 khung giờ liên tiếp';
    if (hasSelection) {
      final first = provider.selectedSlots.first.startTime;
      final last = provider.selectedSlots.last.endTime;
      slotSummaryText = '$count khung giờ đã chọn ($first - $last)';
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MatchColors.line)),
        ),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slotSummaryText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: MatchColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasSelection ? currencyFormat.format(courtTotal) : '0 đ',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: MatchColors.ink,
                          letterSpacing: -.5,
                        ),
                      ),
                      if (hasSelection)
                        Text(
                          'hoặc ~${currencyFormat.format((courtTotal / 4).round())}/người (chia 4)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111315),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
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
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  final String label;
  final Color color;
  final bool border;
  const _SlotLegend(this.label, this.color, {this.border = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: border ? Border.all(color: MatchColors.line) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: MatchColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
