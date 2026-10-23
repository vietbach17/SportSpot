import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/date_selector_widget.dart';
import '../../widgets/match_ui.dart';
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

    return MatchTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text(provider.venueDetail?.name ?? 'Đặt Khung Giờ'),
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
              return ChoiceChip(
                showCheckmark: false,
                label: Text(sub.name),
                selected: isSelected,
                selectedColor: MatchColors.blue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : MatchColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? MatchColors.blue : MatchColors.line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                onSelected: (selected) {
                  if (selected) {
                    provider.selectSubVenue(sub);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            height: 74,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEBF3FC), Color(0xFFF3F7FC), Color(0xFFEBF3FC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x332563EB)),
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
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('C1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.selectedSubVenue?.name ?? 'Sân thi đấu tiêu chuẩn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MatchColors.ink), overflow: TextOverflow.ellipsis, maxLines: 1),
                            const Text('BWF Level 2 Certified • Pro Cushioned', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1),
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Text('LIVE CLEAR', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
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
      slotSummaryText = '$count slot đã chọn ($first - $last)';
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
                          'hoặc ~' + currencyFormat.format((courtTotal / 4).round()) + '/người (chia 4)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
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
