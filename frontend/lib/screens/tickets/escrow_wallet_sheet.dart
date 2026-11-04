import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import 'bank_withdrawal_dialog.dart';

class EscrowWalletSheet extends StatefulWidget {
  final TicketProvider provider;

  const EscrowWalletSheet({super.key, required this.provider});

  static Future<void> show(BuildContext context, TicketProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EscrowWalletSheet(provider: provider),
    );
  }

  @override
  State<EscrowWalletSheet> createState() => _EscrowWalletSheetState();
}

class _EscrowWalletSheetState extends State<EscrowWalletSheet> {
  String _selectedFilter = 'All'; // 'All', 'Holding', 'Settled', 'Refunded', 'Withdrawal'

  String _formatVnd(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount).replaceAll(',', '.')} đ';
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  List<TransactionHistoryModel> _filterTransactions(List<TransactionHistoryModel> list) {
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Holding') return list.where((t) => t.status == 'Holding').toList();
    if (_selectedFilter == 'Settled') return list.where((t) => t.status == 'Settled').toList();
    if (_selectedFilter == 'Refunded') return list.where((t) => t.status == 'Refunded').toList();
    if (_selectedFilter == 'Withdrawal') {
      return list.where((t) => t.status == 'Processing' || t.bookingCode == 'WITHDRAWAL').toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = widget.provider;
    final transactions = _filterTransactions(provider.transactions);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Ký Quỹ Escrow & Ví SportSpot',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // 1. Two Summary Cards
                Row(
                  children: [
                    // Card Ví Hoàn Tiền
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'VÍ HOÀN TIỀN',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                ),
                                Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF047857)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatVnd(provider.walletBalance),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF047857),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.send_to_mobile_rounded, size: 14),
                                label: const Text('Rút Về NH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => BankWithdrawalDialog(provider: provider),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card Escrow Tạm Giữ
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ESCROW TẠM GIỮ',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                                Icon(Icons.lock_clock_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatVnd(provider.escrowHoldingTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '✓ Giữ an toàn đến check-in',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Giải thích cơ chế Escrow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242834) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cơ chế ký quỹ Escrow bảo vệ người chơi: Tiền cọc giữ ở hệ thống trung gian và chỉ giải ngân cho chủ sân khi quét QR nhận sân thành công.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Filter Tabs
                const Text('Biến Động Dòng Tiền & Giao Dịch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'Tất Cả (${provider.transactions.length})'),
                      const SizedBox(width: 8),
                      _filterChip('Holding', 'Ký Quỹ Holding'),
                      const SizedBox(width: 8),
                      _filterChip('Settled', 'Đã Giải Ngân'),
                      const SizedBox(width: 8),
                      _filterChip('Refunded', 'Hoàn Cọc'),
                      const SizedBox(width: 8),
                      _filterChip('Withdrawal', 'Rút Tiền NH'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Transactions List
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có giao dịch nào trong danh mục này',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.map((txn) => _buildTransactionCard(txn, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
    );
  }

  Widget _buildTransactionCard(TransactionHistoryModel txn, bool isDark) {
    Color statusColor;
    String statusLabel;
    IconData icon;

    switch (txn.status) {
      case 'Holding':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Ký Quỹ Tạm Giữ';
        icon = Icons.lock_clock_rounded;
        break;
      case 'Settled':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Đã Giải Ngân';
        icon = Icons.check_circle_rounded;
        break;
      case 'Refunded':
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'Hoàn Tiền Vào Ví';
        icon = Icons.replay_rounded;
        break;
      case 'Processing':
        statusColor = const Color(0xFF9333EA);
        statusLabel = 'Đang Xử Lý Rút';
        icon = Icons.account_balance_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = txn.status;
        icon = Icons.payment_rounded;
    }

    final isPositive = txn.status == 'Refunded';
    final isWithdrawal = txn.status == 'Processing' || txn.bookingCode == 'WITHDRAWAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242834) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.venueName,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${txn.transactionCode} • ${_formatDate(txn.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : (isWithdrawal ? '-' : '')}${_formatVnd(txn.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isPositive ? const Color(0xFF16A34A) : (isWithdrawal ? const Color(0xFFDC2626) : null),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
