import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportspot/data/models/ticket_model.dart';
import 'package:sportspot/data/repositories/mock_ticket_repository.dart';
import 'package:sportspot/providers/ticket_provider.dart';
import 'package:sportspot/screens/tickets/my_tickets_screen.dart';
import 'package:sportspot/screens/tickets/ticket_qr_detail_screen.dart';
import 'dart:io';
import 'test_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('Module 5 Unit Tests - Payment Escrow, SHA-256 QR & Tiered Cancellation', () {
    test('SHA-256 QR Payload verification settles Escrow and blocks tampering/replay', () async {
      final repo = MockTicketRepository();
      final ticketsRes = await repo.getMyTickets();
      final upcomingHostTicket = ticketsRes.tickets.firstWhere((t) => t.bookingId == 501);

      expect(upcomingHostTicket.escrowStatus, 'Holding');
      expect(upcomingHostTicket.qrPayload, startsWith('SPORTSPOT|SP-882410|1|Host|'));

      // 1. Giả mạo chữ ký SHA-256 -> Bị từ chối
      final tamperedPayload =
          '${upcomingHostTicket.qrPayload.substring(0, upcomingHostTicket.qrPayload.length - 4)}FFFF';
      await expectLater(
        repo.verifyQrCheckIn(tamperedPayload),
        throwsException,
      );

      // 2. Quét mã QR hợp lệ -> Giải ngân Escrow từ Holding sang Settled
      final verifyRes = await repo.verifyQrCheckIn(upcomingHostTicket.qrPayload);
      expect(verifyRes['bookingCode'], 'SP-882410');
      expect(verifyRes['escrowStatus'], 'Settled');

      final updatedTickets = await repo.getMyTickets();
      final checkedInTicket = updatedTickets.tickets.firstWhere((t) => t.bookingId == 501);
      expect(checkedInTicket.isCheckedIn, isTrue);
      expect(checkedInTicket.status, 'Completed');
      expect(checkedInTicket.escrowStatus, 'Settled');

      // 3. Quét lại lần 2 (Replay Attack) -> Bị chặn
      await expectLater(
        repo.verifyQrCheckIn(upcomingHostTicket.qrPayload),
        throwsException,
      );
    });

    test('Tiered Cancellation Policy computes 100%, 50%, and 0% refunds accurately', () async {
      final baseTime = DateTime(2026, 10, 25, 10, 0);

      TicketModel buildSampleTicket(String playDate, String startTime) {
        return TicketModel(
          bookingId: 900,
          bookingCode: 'SP-900900',
          venueId: 1,
          venueName: 'Sân Cầu Lông Viettel',
          subVenueName: 'Sân VIP 1',
          sportName: 'Cầu lông',
          address: 'Cầu Giấy, Hà Nội',
          playDate: playDate,
          timeSlots: ['$startTime-20:00'],
          userRoleInMatch: 'Host',
          courtPrice: 200000,
          totalPrice: 200000,
          depositAmount: 200000,
          remainingBalance: 0,
          status: 'Upcoming',
          escrowStatus: 'Holding',
          qrPayload: MockTicketRepository.buildSignedQrPayload('SP-900900', 1, 'Host'),
          isCheckedIn: false,
        );
      }

      // Mốc 1: Cách 8 giờ (>= 4h) -> Hoàn 100% (200.000đ), Phạt 0đ
      final t100 = buildSampleTicket('2026-10-25', '18:00');
      final p100 = t100.calculateRefundPreview(fromTime: baseTime);
      expect(p100.refundPercentage, 100);
      expect(p100.refundAmount, 200000);
      expect(p100.penaltyAmount, 0);

      // Mốc 2: Cách 3 giờ (Từ 2h đến < 4h) -> Hoàn 50% (100.000đ), Phạt 50% (100.000đ)
      final t50 = buildSampleTicket('2026-10-25', '13:00');
      final p50 = t50.calculateRefundPreview(fromTime: baseTime);
      expect(p50.refundPercentage, 50);
      expect(p50.refundAmount, 100000);
      expect(p50.penaltyAmount, 100000);

      // Mốc 3: Cách 1 giờ (< 2h) -> Hoàn 0% (0đ), Phạt 100% (200.000đ)
      final t0 = buildSampleTicket('2026-10-25', '11:00');
      final p0 = t0.calculateRefundPreview(fromTime: baseTime);
      expect(p0.refundPercentage, 0);
      expect(p0.refundAmount, 0);
      expect(p0.penaltyAmount, 200000);
    });

    test('MockTicketRepository cancels ticket and credits user WalletBalance', () async {
      final repo = MockTicketRepository();
      final beforeWallet = (await repo.getWalletAndHistory()).walletBalance;

      final tickets = (await repo.getMyTickets()).tickets;
      final ticket501 = tickets.firstWhere((t) => t.bookingId == 501); // >= 4h ahead -> 100% refund (135,000đ)

      final cancelResult = await repo.cancelTicket(ticket501);
      expect(cancelResult.refundAmount, 135000);
      expect(cancelResult.penaltyAmount, 0);

      final afterWallet = (await repo.getWalletAndHistory()).walletBalance;
      expect(afterWallet, beforeWallet + 135000);
    });
  });

  group('Module 5 Widget Tests - MyTicketsScreen & QR Pass UI', () {
    testWidgets('MyTicketsScreen renders Wallet, Escrow, Pre-Match 2h Reminder and Offline Switch',
        (tester) async {
      final mockRepo = MockTicketRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MyTicketsScreen(repository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra hiển thị số dư Ví Hoàn Tiền & Escrow Holding
      expect(find.byKey(const Key('wallet_balance_text')), findsOneWidget);
      expect(find.byKey(const Key('escrow_holding_text')), findsOneWidget);

      // Kiểm tra hiển thị Banner Nhắc lịch trước 2 giờ (Ticket #502 sắp diễn ra)
      expect(find.byKey(const Key('pre_match_reminder_banner')), findsOneWidget);

      // Kiểm tra vé #501 xuất hiện trong danh sách Sắp tới
      expect(find.byKey(const Key('ticket_card_501')), findsOneWidget);

      // Bật công tắc Giả lập Mất mạng (SQLite Offline)
      await tester.tap(find.byKey(const Key('offline_mode_switch')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Đang mở vé từ bộ nhớ SQLite Offline'),
        findsOneWidget,
      );
    });

    testWidgets('TicketQrDetailScreen renders dynamic QR code and SHA-256 payload',
        (tester) async {
      final mockRepo = MockTicketRepository();
      final provider = TicketProvider(repository: mockRepo);
      final sampleTicket = TicketModel(
        bookingId: 501,
        bookingCode: 'SP-882410',
        venueId: 1,
        venueName: 'Sân Cầu Lông Viettel',
        subVenueName: 'Sân VIP 1',
        sportName: 'Cầu lông',
        address: 'Cầu Giấy, Hà Nội',
        playDate: '2026-10-25',
        timeSlots: const ['18:00-19:00', '19:00-20:00'],
        userRoleInMatch: 'Host',
        courtPrice: 240000,
        totalPrice: 240000,
        depositAmount: 120000,
        remainingBalance: 120000,
        status: 'Upcoming',
        escrowStatus: 'Holding',
        qrPayload: MockTicketRepository.buildSignedQrPayload('SP-882410', 1, 'Host'),
        isCheckedIn: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TicketQrDetailScreen(
            ticket: sampleTicket,
            provider: provider,
            isOfflineMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sân Cầu Lông Viettel'), findsOneWidget);
      expect(find.textContaining('SPORTSPOT|SP-882410|1|Host|'), findsOneWidget);
      expect(find.textContaining('SHA-256 Checksum:'), findsOneWidget);
    });
  });
}
