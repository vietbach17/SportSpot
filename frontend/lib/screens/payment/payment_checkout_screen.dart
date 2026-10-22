import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ticket_provider.dart';
import '../tickets/cancel_ticket_dialog.dart';
import '../tickets/ticket_qr_detail_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final TicketProvider ticketProvider;
  final int? initialSubVenueId;
  final String? initialPlayDate;
  final List<int>? initialSlotIds;

  const PaymentCheckoutScreen({
    super.key,
    required this.ticketProvider,
    this.initialSubVenueId,
    this.initialPlayDate,
    this.initialSlotIds,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  static const Color _green = Color(0xFF16A34A);
  static const Color _pastelGreen = Color(0xFFDCFCE7);
  static const Color _red = Color(0xFFDC2626);

  late int _selectedSubVenueId;
  late int _selectedScenarioIndex;
  int _depositPercent = 100;
  String _selectedGateway = 'VNPay';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _venues = [
    {
      'subVenueId': 1,
      'venueName': 'CLB Cầu Lông Cầu Giấy',
      'subVenueName': 'Sân Số 1 (Thảm Yonex)',
      'sportName': 'Cầu lông',
      'pricePerSlot': 120000,
      'icon': Icons.sports_tennis_rounded,
    },
    {
      'subVenueId': 2,
      'venueName': 'Sân Bóng Đá Mini PVV',
      'subVenueName': 'Sân 7A (Cỏ Nhân Tạo)',
      'sportName': 'Bóng đá mini',
      'pricePerSlot': 300000,
      'icon': Icons.sports_soccer_rounded,
    },
    {
      'subVenueId': 3,
      'venueName': 'CLB Pickleball Thảo Điền',
      'subVenueName': 'Court P1 (Mái che)',
      'sportName': 'Pickleball',
      'pricePerSlot': 160000,
      'icon': Icons.sports_baseball_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubVenueId = widget.initialSubVenueId ?? 1;
    _selectedScenarioIndex = 0;
  }

  List<Map<String, dynamic>> _buildTimeScenarios() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final fmt = DateFormat('yyyy-MM-dd');

    return [
      {
        'label': 'Ngày mai (18:00 - 20:00)',
        'badge': 'Hoàn 100% nếu hủy (>= 4h)',
        'playDate': widget.initialPlayDate ?? fmt.format(tomorrow),
        'slotIds': widget.initialSlotIds ?? [13, 14],
        'color': _green,
      },
      {
        'label': 'Tối nay (18:00 - 20:00)',
        'badge': 'Test khung giờ trong ngày',
        'playDate': fmt.format(now),
        'slotIds': [13, 14],
        'color': AppTheme.accentBlue,
      },
      {
        'label': 'Sáng mai (08:00 - 09:00)',
        'badge': '1 Slot đơn lẻ',
        'playDate': fmt.format(tomorrow),
        'slotIds': [3],
        'color': Colors.deepPurple,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _buildTimeScenarios();
    final selectedVenue = _venues.firstWhere(
      (v) => v['subVenueId'] == _selectedSubVenueId,
      orElse: () => _venues.first,
    );
    final selectedScenario = scenarios[_selectedScenarioIndex];
    final slotCount = (selectedScenario['slotIds'] as List<int>).length;
    final totalPrice = (selectedVenue['pricePerSlot'] as int) * slotCount;
    final amountToPay = (totalPrice * _depositPercent) ~/ 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Thanh Toán Escrow & Tạo Vé QR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner giải thích Escrow
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.pastelBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentBlue.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảo vệ Thanh toán Tạm giữ (Escrow Holding)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Khoản thanh toán được hệ thống SportSpot giữ an toàn ở trạng thái Holding và chỉ giải ngân (Settled) cho chủ sân sau khi bạn quét mã QR Check-in hợp lệ.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textDark,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Chọn sân
            const Text(
              '1. Chọn Sân Thi Đấu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ..._venues.map((venue) {
              final isSelected = venue['subVenueId'] == _selectedSubVenueId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedSubVenueId = venue['subVenueId'] as int;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _pastelGreen.withValues(alpha: 0.55)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _green : Colors.grey.shade200,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              isSelected ? _green : AppTheme.background,
                          foregroundColor:
                              isSelected ? Colors.white : AppTheme.textDark,
                          child: Icon(venue['icon'] as IconData, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue['venueName'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${venue['subVenueName']} • ${CancelTicketDialog.formatVnd(venue['pricePerSlot'] as int)}/ca',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? _green : AppTheme.textGray,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // 2. Chọn khung giờ
            const Text(
              '2. Chọn Ngày & Khung Giờ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(scenarios.length, (index) {
              final item = scenarios[index];
              final isSelected = _selectedScenarioIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedScenarioIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentBlue
                            : Colors.grey.shade200,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.textGray,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['label']} (${item['playDate']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['badge'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: item['color'] as Color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppTheme.accentBlue
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // 3. Tỷ lệ thanh toán
            const Text(
              '3. Mức Thanh Toán Tạm Giữ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDepositOption(
                    percent: 100,
                    title: 'Thanh toán 100%',
                    subtitle: CancelTicketDialog.formatVnd(totalPrice),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDepositOption(
                    percent: 50,
                    title: 'Đặt cọc 50%',
                    subtitle: CancelTicketDialog.formatVnd((totalPrice * 50) ~/ 100),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 4. Chọn cổng thanh toán
            const Text(
              '4. Phương Thức Thanh Toán',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            _buildGatewayTile(
              id: 'VNPay',
              title: 'VNPay QR / Cổng VNPay Sandbox',
              subtitle: 'Xác nhận tức thì qua Webhook IPN',
              icon: Icons.qr_code_2_rounded,
              color: Colors.blue.shade700,
            ),
            _buildGatewayTile(
              id: 'MoMo',
              title: 'Ví Điện Tử MoMo Sandbox',
              subtitle: 'Liên kết thanh toán nhanh an toàn',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.pink.shade600,
            ),
            _buildGatewayTile(
              id: 'Wallet',
              title:
                  'Ví SportSpot (${CancelTicketDialog.formatVnd(widget.ticketProvider.walletBalance)})',
              subtitle: 'Sử dụng số dư hoàn tiền trong ví của bạn',
              icon: Icons.savings_rounded,
              color: _green,
            ),
            _buildGatewayTile(
              id: 'ATM',
              title: 'Thẻ ATM Nội Địa / Napas',
              subtitle: 'Hỗ trợ hơn 40 ngân hàng tại Việt Nam',
              icon: Icons.credit_card_rounded,
              color: Colors.teal.shade700,
            ),

            const SizedBox(height: 18),

            // Tóm tắt đơn hàng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Tổng tiền sân',
                    CancelTicketDialog.formatVnd(totalPrice),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Mức đặt cọc / thanh toán',
                    '$_depositPercent%',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Cổng thanh toán', _selectedGateway),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền nạp vào Escrow',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        CancelTicketDialog.formatVnd(amountToPay),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              key: const Key('confirm_escrow_payment_btn'),
              onPressed: _isSubmitting
                  ? null
                  : () => _handleCheckout(
                        selectedScenario['playDate'] as String,
                        selectedScenario['slotIds'] as List<int>,
                      ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _isSubmitting
                    ? 'Đang xử lý giao dịch Escrow...'
                    : 'Thanh Toán ${CancelTicketDialog.formatVnd(amountToPay)} & Nhận Mã QR',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositOption({
    required int percent,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _depositPercent == percent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _depositPercent = percent),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _pastelGreen.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _green : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: _green,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGateway == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedGateway = id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? color : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckout(String playDate, List<int> slotIds) async {
    setState(() => _isSubmitting = true);
    final ticket = await widget.ticketProvider.createSandboxBookingAndPay(
      subVenueId: _selectedSubVenueId,
      playDate: playDate,
      slotIds: slotIds,
      depositPercent: _depositPercent,
      paymentGateway: _selectedGateway,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ticketProvider.errorMessage ?? 'Thanh toán thất bại',
          ),
          backgroundColor: _red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thanh toán thành công! Đã tạo vé QR SHA-256 & lưu SQLite Offline.',
        ),
        backgroundColor: _green,
      ),
    );

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TicketQrDetailScreen(
          ticket: ticket,
          provider: widget.ticketProvider,
          isOfflineMode: widget.ticketProvider.isFromSqliteOffline,
        ),
      ),
    );
  }
}
