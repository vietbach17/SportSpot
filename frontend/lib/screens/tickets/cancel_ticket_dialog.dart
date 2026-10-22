import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_model.dart';

class CancelTicketDialog extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onConfirmCancel;

  const CancelTicketDialog({
    super.key,
    required this.ticket,
    required this.onConfirmCancel,
  });

  static String formatVnd(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${amount < 0 ? '-' : ''}$buffer đ';
  }

  @override
  Widget build(BuildContext context) {
    final preview = ticket.calculateRefundPreview();
    final hours = preview.hoursBeforeMatch;

    Color badgeColor;
    if (preview.refundPercentage == 100) {
      badgeColor = const Color(0xFF16A34A);
    } else if (preview.refundPercentage == 50) {
      badgeColor = const Color(0xFFD97706);
    } else {
      badgeColor = const Color(0xFFDC2626);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.policy_rounded, color: badgeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xác nhận Hủy Vé Đặt Sân',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Mã vé: ${ticket.bookingCode} • Còn ${hours > 0 ? hours.toStringAsFixed(1) : '0'} giờ trước trận',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.policyTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.policyDetail,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bảng Chính Sách Phạt Bậc Thang (Tiered Policy):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 8),
              _buildTierRow(
                label: 'Hủy sớm >= 4 tiếng',
                value: 'Hoàn 100% cọc',
                isActive: preview.refundPercentage == 100,
                activeColor: const Color(0xFF16A34A),
              ),
              _buildTierRow(
                label: 'Hủy từ 2h đến < 4 tiếng',
                value: 'Hoàn 50% • Phạt 50%',
                isActive: preview.refundPercentage == 50,
                activeColor: const Color(0xFFD97706),
              ),
              _buildTierRow(
                label: 'Hủy sát giờ (< 2 tiếng)',
                value: 'Phạt 100% (0% hoàn)',
                isActive: preview.refundPercentage == 0,
                activeColor: const Color(0xFFDC2626),
              ),
              const Divider(height: 24),
              _buildSummaryRow('Tiền cọc Escrow đã đóng:', formatVnd(ticket.depositAmount)),
              const SizedBox(height: 6),
              _buildSummaryRow(
                'Số tiền hoàn về Ví SportSpot (${preview.refundPercentage}%):',
                '+${formatVnd(preview.refundAmount)}',
                valueColor: const Color(0xFF16A34A),
                isBold: true,
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(
                'Phí phạt bồi thường chủ sân:',
                '-${formatVnd(preview.penaltyAmount)}',
                valueColor: preview.penaltyAmount > 0 ? const Color(0xFFDC2626) : AppTheme.textGray,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Giữ lại vé'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirmCancel();
                      },
                      child: const Text('Xác nhận hủy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierRow({
    required String label,
    required String value,
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? activeColor : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: isActive ? activeColor : AppTheme.textGray,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : AppTheme.textDark,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isActive ? activeColor : AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
