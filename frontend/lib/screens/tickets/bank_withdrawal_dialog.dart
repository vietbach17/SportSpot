import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ticket_provider.dart';

class BankWithdrawalDialog extends StatefulWidget {
  final TicketProvider provider;

  const BankWithdrawalDialog({super.key, required this.provider});

  static Future<void> show(BuildContext context, TicketProvider provider) {
    return showDialog(
      context: context,
      builder: (_) => BankWithdrawalDialog(provider: provider),
    );
  }

  @override
  State<BankWithdrawalDialog> createState() => _BankWithdrawalDialogState();
}

class _BankWithdrawalDialogState extends State<BankWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _banks = const [
    'Vietcombank (VCB)',
    'MB Bank (Quân Đội)',
    'Techcombank (TCB)',
    'ACB (Á Châu)',
    'VPBank (Việt Nam Thịnh Vượng)',
    'BIDV (Đầu Tư & Phát Triển)',
    'Agribank (Nông Nghiệp)',
    'TPBank (Tiên Phong)',
    'Sacombank (Sài Gòn Thương Tín)',
  ];

  late String _selectedBank;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedBank = _banks.first;
    // Điền mặc định toàn bộ số dư ví nếu có
    if (widget.provider.walletBalance > 0) {
      _amountController.text = widget.provider.walletBalance.toString();
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount).replaceAll(',', '.')} đ';
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0 || amount > widget.provider.walletBalance) {
      setState(() {
        _errorMessage = 'Số tiền rút không hợp lệ hoặc vượt quá số dư ví hiện có.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.provider.requestBankWithdrawal(
        bankName: _selectedBank,
        accountNumber: _accountNumberController.text.trim(),
        accountHolder: _accountHolderController.text.trim().toUpperCase(),
        amount: amount,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng dialog nhập

      // Mở dialog biên lai xác nhận thành công
      _showWithdrawalSuccessDialog(res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showWithdrawalSuccessDialog(Map<String, dynamic> res) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yêu Cầu Rút Tiền Đã Tiếp Nhận!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mã tra soát: ${res['withdrawalCode']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      _receiptRow('Số tiền rút:', _formatVnd(res['amount'] as int), isBold: true, color: const Color(0xFF16A34A)),
                      const SizedBox(height: 8),
                      _receiptRow('Ngân hàng:', res['bankName']?.toString() ?? ''),
                      const SizedBox(height: 6),
                      _receiptRow('Số tài khoản:', res['accountNumber']?.toString() ?? ''),
                      const SizedBox(height: 6),
                      _receiptRow('Chủ tài khoản:', res['accountHolder']?.toString() ?? ''),
                      const Divider(height: 18),
                      _receiptRow('Số dư ví còn lại:', _formatVnd(res['remainingBalance'] as int)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '💡 Hệ thống sẽ kiểm tra đối soát hoàn cọc và chuyển tiền về tài khoản ngân hàng của bạn trong vòng tối đa 24 giờ làm việc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textGray, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Đã Hiểu & Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textGray)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.provider.walletBalance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rút Tiền Về Ngân Hàng',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                          ),
                          Text(
                            'Hoàn tiền cọc & số dư về tài khoản ngân hàng',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Số Dư Ví Hiện Tại
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Số dư ví hoàn tiền:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                      ),
                      Text(
                        _formatVnd(balance),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Dropdown Ngân hàng
                const Text('Ngân hàng thụ hưởng', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.account_balance, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
                const SizedBox(height: 14),

                // 2. Số tài khoản
                const Text('Số tài khoản ngân hàng', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 190367891234',
                    prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 6) {
                      return 'Vui lòng nhập số tài khoản hợp lệ (ít nhất 6 số)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Tên chủ thẻ
                const Text('Tên chủ tài khoản (Viết hoa)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountHolderController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: NGUYEN VAN A',
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên chủ tài khoản';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 4. Số tiền muốn rút
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text('Số tiền muốn rút (VNĐ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                    if (balance > 0)
                      GestureDetector(
                        onTap: () => setState(() => _amountController.text = balance.toString()),
                        child: const Text(
                          'Rút tất cả',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 100000',
                    prefixIcon: const Icon(Icons.monetization_on_rounded, size: 20),
                    suffixText: 'đ',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    final n = int.tryParse(val ?? '') ?? 0;
                    if (n <= 0) return 'Vui lòng nhập số tiền lớn hơn 0';
                    if (n < 50000) return 'Số tiền rút tối thiểu là 50.000 đ';
                    if (n > balance) return 'Số tiền rút không được vượt quá số dư hiện có';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy Bỏ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_isSubmitting || balance <= 0) ? null : _submitWithdrawal,
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Xác Nhận Rút'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
