import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../widgets/recruitment_form.dart';
import '../../widgets/match_ui.dart';

/// A small checkout using booking APIs; RecruitmentForm can also be embedded in its full checkout.
class MatchCheckoutScreen extends StatefulWidget {
  final ApiClient? apiClient;
  const MatchCheckoutScreen({super.key, this.apiClient});
  @override
  State<MatchCheckoutScreen> createState() => _MatchCheckoutScreenState();
}

class _MatchCheckoutScreenState extends State<MatchCheckoutScreen> {
  late final api = widget.apiClient ?? ApiClient();
  final form = GlobalKey<FormState>();
  List<dynamic> venues = [], courts = [], slots = [];
  final selected = <int>{};
  int? venueId, courtId;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  RecruitmentValue recruitment = const RecruitmentValue();
  bool loading = true, submitting = false;
  String? error;
  String get day =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  int get price => slots
      .where((s) => selected.contains(s['slotId']))
      .fold<int>(0, (sum, s) => sum + (s['price'] as int));
  @override
  void initState() {
    super.initState();
    loadVenues();
  }

  Future<void> loadVenues() async {
    try {
      final data = await api.get('/api/venues');
      if (mounted) {
        setState(() {
          venues = data;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          loading = false;
        });
      }
    }
  }

  Future<void> selectVenue(int id) async {
    setState(() {
      loading = true;
      error = null;
      venueId = id;
      courtId = null;
      courts = [];
      slots = [];
      selected.clear();
    });
    try {
      final data = await api.get('/api/venues/$id');
      if (mounted) {
        setState(() {
          courts = (data['subVenues'] as List)
              .where((c) => c['isActive'] == true)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadSlots() async {
    if (courtId == null) return;
    setState(() {
      loading = true;
      selected.clear();
      slots = [];
      error = null;
    });
    try {
      final data = await api.get(
        '/api/venues/$venueId/slots?subVenueId=$courtId&playDate=$day',
      );
      if (mounted) setState(() => slots = data);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void toggle(dynamic slot) {
    final id = slot['slotId'] as int;
    final next = {...selected};
    next.contains(id) ? next.remove(id) : next.add(id);
    final ordered = slots.where((s) => next.contains(s['slotId'])).toList()
      ..sort(
        (a, b) =>
            (a['startTime'] as String).compareTo(b['startTime'] as String),
      );
    bool consecutive = true;
    for (var i = 1; i < ordered.length; i++) {
      if (ordered[i - 1]['endTime'] != ordered[i]['startTime']) {
        consecutive = false;
      }
    }
    if (next.length > 3 || !consecutive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn tối đa 3 khung giờ liên tiếp.')),
      );
      return;
    }
    setState(() {
      selected.clear();
      selected.addAll(next);
    });
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() ||
        selected.isEmpty ||
        !recruitment.valid) {
      return;
    }
    setState(() => submitting = true);
    try {
      final booking = await api.post('/api/bookings', {
        'subVenueId': courtId,
        'playDate': day,
        'slotIds': selected.toList()..sort(),
        'services': [],
        'depositPercentage': 30,
        'paymentGateway': 'MockPayment',
        ...recruitment.toJson(),
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đặt sân thành công'),
          content: Text(
            '${booking['bookingCode']}\nTiền sân: ${money(booking['courtPrice'])}\nCọc giả lập: ${money(booking['depositAmount'])}\n${recruitment.enabled ? 'Kèo đã xuất hiện trên bảng tin.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
        await loadSlots();
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => MatchTheme(
    child: Scaffold(
      appBar: AppBar(title: const Text('Đặt sân & tuyển vãng lai')),
      bottomNavigationBar: SafeArea(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tiền sân tạm tính',
                          style: TextStyle(
                            fontSize: 13,
                            color: MatchColors.muted,
                          ),
                        ),
                      ),
                      Text(
                        money(price),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: MatchColors.ink,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading || submitting || selected.isEmpty
                          ? null
                          : submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        submitting
                            ? 'Đang xác nhận...'
                            : 'Xác nhận đặt sân · Cọc mock 30%',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: submitting,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const MatchHero(
                    eyebrow: 'BUILD YOUR TEAM',
                    title: 'Chọn sân tốt.\nGọi đồng đội hay.',
                    subtitle: 'Một lịch hẹn thể thao, thêm những kết nối mới.',
                  ),
                  const SizedBox(height: 20),
                  if (loading || submitting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (error != null) ...[
                    MatchEmptyState(
                      title: 'Chưa tải được dữ liệu sân',
                      message: error!,
                      icon: Icons.wifi_off_rounded,
                      onRetry: () {
                        if (venueId == null) {
                          loadVenues();
                        } else if (courtId == null) {
                          selectVenue(venueId!);
                        } else {
                          loadSlots();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  MatchSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MatchSectionTitle(
                          'Địa điểm thi đấu',
                          'Chọn cụm sân và sân con bạn muốn chơi.',
                          step: '01',
                        ),
                        DropdownButtonFormField<int>(
                          initialValue: venueId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Cụm sân',
                            prefixIcon: Icon(Icons.stadium_outlined, size: 21),
                          ),
                          items: venues
                              .map(
                                (v) => DropdownMenuItem<int>(
                                  value: v['id'],
                                  child: Text(
                                    v['name'],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: loading ? null : (id) => selectVenue(id!),
                          validator: (v) => v == null ? 'Chọn cụm sân' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          key: ValueKey(venueId),
                          initialValue: courtId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sân con',
                            prefixIcon: Icon(Icons.grid_view_rounded, size: 20),
                          ),
                          items: courts
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: c['id'],
                                  child: Text(c['name']),
                                ),
                              )
                              .toList(),
                          onChanged: loading
                              ? null
                              : (id) {
                                  courtId = id;
                                  loadSlots();
                                },
                          validator: (v) => v == null ? 'Chọn sân con' : null,
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
                          'Lên lịch ra sân',
                          'Chọn tối đa 3 khung giờ liên tiếp.',
                          step: '02',
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              color: MatchColors.blue,
                              size: 21,
                            ),
                            label: Text(
                              'Ngày chơi: ${matchDay(day)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: loading
                                ? null
                                : () async {
                                    final now = DateUtils.dateOnly(
                                      DateTime.now(),
                                    );
                                    final chosen = await showDatePicker(
                                      context: context,
                                      initialDate: date,
                                      firstDate: now,
                                      lastDate: now.add(
                                        const Duration(days: 6),
                                      ),
                                    );
                                    if (chosen != null && mounted) {
                                      setState(() => date = chosen);
                                      await loadSlots();
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _SlotLegend(
                              'Còn trống',
                              Colors.white,
                              border: true,
                            ),
                            _SlotLegend('Đang chọn', MatchColors.blue),
                            _SlotLegend('Đã kín / đã qua', MatchColors.line),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!loading && slots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              courtId == null
                                  ? 'Chọn sân để xem các khung giờ còn trống.'
                                  : 'Chưa có khung giờ. Chọn sân hoặc ngày khác.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: MatchColors.muted,
                                height: 1.6,
                              ),
                            ),
                          ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 520
                                ? 4
                                : constraints.maxWidth >= 300
                                ? 3
                                : 2;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 8) /
                                columns;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: slots.map((s) {
                                final start = DateTime.tryParse(
                                  '${day}T${s['startTime']}:00',
                                );
                                final unavailable =
                                    s['isBooked'] == true ||
                                    start == null ||
                                    !start.isAfter(DateTime.now());
                                final active = selected.contains(s['slotId']);
                                return SizedBox(
                                  width: width,
                                  child: Semantics(
                                    selected: active,
                                    button: true,
                                    enabled: !unavailable && !loading,
                                    child: Material(
                                      color: active
                                          ? MatchColors.blue
                                          : unavailable
                                          ? const Color(0xFFF0F3F7)
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        side: BorderSide(
                                          color: active
                                              ? MatchColors.blue
                                              : MatchColors.line,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: unavailable || loading
                                            ? null
                                            : () => toggle(s),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 13,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${s['startTime']}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: active
                                                      ? Colors.white
                                                      : unavailable
                                                      ? const Color(0xFF9DAAB8)
                                                      : MatchColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'đến ${s['endTime']}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: active
                                                      ? const Color(0xFFD5E3FF)
                                                      : MatchColors.muted,
                                                ),
                                              ),
                                              const SizedBox(height: 9),
                                              Text(
                                                money(s['price']),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: active
                                                      ? Colors.white
                                                      : MatchColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const MatchSectionTitle(
                    'Tạo đội hình của bạn',
                    'Có sẵn đồng đội hoặc mở tuyển thêm người chơi.',
                    step: '03',
                  ),
                  RecruitmentForm(
                    courtPrice: price,
                    onChanged: (v) => setState(() => recruitment = v),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: MatchColors.muted,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cọc 30% qua thanh toán giả lập. Chi phí tuyển được tính riêng từ tiền sân.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            color: MatchColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: border ? Border.all(color: MatchColors.muted) : null,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: MatchColors.muted),
      ),
    ],
  );
}
