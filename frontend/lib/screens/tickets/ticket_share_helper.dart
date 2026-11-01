import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TicketShareHelper {
  static String formatTicketShareText({
    required String bookingCode,
    required String venueName,
    required String subVenueName,
    required String sportName,
    required String playDate,
    required List<String> timeSlots,
    required String status,
    required String escrowStatus,
  }) {
    return '''🏸 THẺ VÉ VÀO SÂN SPORTSPOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Mã đặt sân: $bookingCode
• Sân đấu: $venueName - $subVenueName ($sportName)
• Ngày thi đấu: $playDate
• Khung giờ: ${timeSlots.join(', ')}
• Trạng thái cọc: Ký quỹ Escrow $escrowStatus
• Hướng dẫn check-in: Xuất trình mã này tại quầy lễ tân để nhận sân!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tải app SportSpot để cùng ghép kèo & đặt sân thể thao!''';
  }

  static void shareTicket(
    BuildContext context, {
    required String bookingCode,
    required String venueName,
    required String subVenueName,
    required String sportName,
    required String playDate,
    required List<String> timeSlots,
    required String status,
    required String escrowStatus,
  }) {
    final text = formatTicketShareText(
      bookingCode: bookingCode,
      venueName: venueName,
      subVenueName: subVenueName,
      sportName: sportName,
      playDate: playDate,
      timeSlots: timeSlots,
      status: status,
      escrowStatus: escrowStatus,
    );

    Clipboard.setData(ClipboardData(text: text));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.share_rounded, color: Color(0xFF2563EB), size: 22),
                SizedBox(width: 8),
                Text(
                  'Chia Sẻ Vé Thi Đấu Cho Đồng Đội',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Đã sao chép nội dung vé vào bộ nhớ tạm. Bạn có thể dán (paste) trực tiếp vào Zalo, Messenger hoặc SMS:',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao Chép Lại & Đóng'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF16A34A),
                      content: Text('Đã sao chép vé thi đấu thành công!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
