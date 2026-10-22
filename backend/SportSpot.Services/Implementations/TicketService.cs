using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class TicketService : ITicketService
{
    private readonly IUnitOfWork _unitOfWork;

    public TicketService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<BookingResponseDto>>> GetMyTicketsAsync(int userId)
    {
        if (userId <= 0)
        {
            return ApiResponse<List<BookingResponseDto>>.Fail("Vui lòng đăng nhập để xem danh sách vé", 401);
        }

        // 1. Lấy các vé mà người dùng là Đội trưởng / Người đặt sân (Host)
        var hostBookings = await _unitOfWork.Bookings.GetUserBookingsWithDetailsAsync(userId);
        var result = hostBookings.Select(b =>
        {
            var qrPayload = QrChecksumHelper.BuildSignedQrPayload(b.BookingCode, b.UserId, "Host");
            var escrowTx = b.Transactions.OrderByDescending(t => t.CreatedAt).FirstOrDefault();
            var escrowStatus = escrowTx?.Status ?? (b.Status == "Completed" ? "Settled" : b.Status == "Cancelled" ? "Refunded" : "Holding");

            return new BookingResponseDto
            {
                BookingId = b.Id,
                BookingCode = b.BookingCode,
                VenueId = b.SubVenue?.VenueId ?? 0,
                VenueName = b.SubVenue?.Venue?.Name ?? string.Empty,
                SubVenueName = b.SubVenue?.Name ?? string.Empty,
                SportName = b.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
                Address = b.SubVenue?.Venue?.Address ?? string.Empty,
                PlayDate = b.PlayDate,
                TimeSlots = b.BookingDetails
                    .OrderBy(bd => bd.SlotId)
                    .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                    .ToList(),
                UserRoleInMatch = "Host",
                CourtPrice = b.CourtPrice,
                ServicesPrice = b.ServicesPrice,
                TotalPrice = b.TotalPrice,
                DepositAmount = b.DepositAmount,
                RemainingBalance = b.RemainingBalance,
                Status = b.Status,
                EscrowStatus = escrowStatus,
                QrPayload = qrPayload,
                IsCheckedIn = b.IsCheckedIn
            };
        }).ToList();

        // 2. Lấy thêm các vé mà người dùng tham gia ghép kèo vãng lai (JoinedPlayer từ Module 4)
        var joinedMembers = await _unitOfWork.Matches.GetUserJoinedMatchesWithDetailsAsync(userId);
        foreach (var mm in joinedMembers)
        {
            var b = mm.OpenMatch?.Booking;
            if (b == null || result.Any(r => r.BookingId == b.Id && r.UserRoleInMatch == "Host"))
            {
                continue;
            }

            var qrPayload = !string.IsNullOrWhiteSpace(mm.TicketQrPayload)
                ? mm.TicketQrPayload!
                : QrChecksumHelper.BuildSignedQrPayload(b.BookingCode, userId, "JoinedPlayer");

            var memberTx = b.Transactions
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefault(t => t.UserId == userId);

            result.Add(new BookingResponseDto
            {
                BookingId = b.Id,
                BookingCode = b.BookingCode,
                VenueId = b.SubVenue?.VenueId ?? 0,
                VenueName = b.SubVenue?.Venue?.Name ?? string.Empty,
                SubVenueName = b.SubVenue?.Name ?? string.Empty,
                SportName = b.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
                Address = b.SubVenue?.Venue?.Address ?? string.Empty,
                PlayDate = b.PlayDate,
                TimeSlots = b.BookingDetails
                    .OrderBy(bd => bd.SlotId)
                    .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                    .ToList(),
                UserRoleInMatch = "JoinedPlayer",
                MatchId = mm.MatchId,
                CourtPrice = mm.PaidAmount,
                ServicesPrice = 0,
                TotalPrice = mm.PaidAmount,
                DepositAmount = mm.PaidAmount,
                RemainingBalance = 0,
                Status = b.Status == "Cancelled" ? "Cancelled" : (mm.IsCheckedIn ? "Completed" : "Upcoming"),
                EscrowStatus = memberTx?.Status ?? (mm.IsCheckedIn ? "Settled" : "Holding"),
                QrPayload = qrPayload,
                IsCheckedIn = mm.IsCheckedIn
            });
        }

        var ordered = result
            .OrderByDescending(r => r.PlayDate)
            .ThenByDescending(r => r.BookingId)
            .ToList();

        return ApiResponse<List<BookingResponseDto>>.Ok(ordered, "Lấy danh sách vé thành công");
    }

    public async Task<ApiResponse<object>> VerifyQrAndSettleEscrowAsync(CheckInRequest request)
    {
        if (!QrChecksumHelper.ValidateSignedQrPayload(
            request.QrPayload, out var bookingCode, out var scannedUserId, out var role))
        {
            return ApiResponse<object>.Fail("Mã QR không hợp lệ hoặc chữ ký bảo mật (SHA-256 Checksum) đã bị chỉnh sửa");
        }

        var booking = await _unitOfWork.Bookings.GetBookingByCodeWithDetailsAsync(bookingCode);
        if (booking == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy thông tin đơn đặt sân", 404);
        }

        if (booking.Status == "Cancelled")
        {
            return ApiResponse<object>.Fail("Đơn đặt sân này đã bị hủy, không thể check-in", 400);
        }

        // Trường hợp 1: Quét vé của Thành viên ghép kèo vãng lai (JoinedPlayer)
        if (string.Equals(role, "JoinedPlayer", StringComparison.OrdinalIgnoreCase))
        {
            var member = booking.OpenMatch?.MatchMembers.FirstOrDefault(m => m.UserId == scannedUserId);
            if (member == null)
            {
                return ApiResponse<object>.Fail("Không tìm thấy thông tin thành viên vãng lai trong kèo này", 404);
            }

            if (member.IsCheckedIn)
            {
                return ApiResponse<object>.Fail($"Vé vãng lai này đã được check-in lúc {member.CheckedInAt:HH:mm dd/MM/yyyy}");
            }

            member.IsCheckedIn = true;
            member.CheckedInAt = DateTime.UtcNow;

            foreach (var tx in booking.Transactions.Where(t => t.UserId == scannedUserId && t.Status == "Holding"))
            {
                tx.Status = "Settled";
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<object>.Ok(new
            {
                bookingCode = booking.BookingCode,
                customerName = member.User?.FullName ?? $"Khách #{scannedUserId}",
                role = "JoinedPlayer",
                subVenueName = booking.SubVenue?.Name,
                venueName = booking.SubVenue?.Venue?.Name,
                escrowStatus = "Settled",
                checkedInAt = member.CheckedInAt
            }, "Check-in vé vãng lai thành công! Tiền đóng góp đã được giải ngân (Settled).");
        }

        // Trường hợp 2: Quét vé của Đội trưởng / Chủ đơn đặt sân (Host)
        if (booking.IsCheckedIn)
        {
            return ApiResponse<object>.Fail($"Vé này đã được check-in lúc {booking.CheckedInAt:HH:mm dd/MM/yyyy}");
        }

        booking.IsCheckedIn = true;
        booking.CheckedInAt = DateTime.UtcNow;
        booking.Status = "Completed";

        // Giải ngân Escrow: Chuyển toàn bộ các giao dịch Holding của đơn này sang Settled (BR-PAY-03)
        int settledCount = 0;
        int settledAmount = 0;
        foreach (var tx in booking.Transactions.Where(t => t.Status == "Holding"))
        {
            tx.Status = "Settled";
            settledCount++;
            settledAmount += tx.Amount;
        }

        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            bookingCode = booking.BookingCode,
            customerName = booking.User?.FullName ?? $"Khách #{booking.UserId}",
            role = "Host",
            subVenueName = booking.SubVenue?.Name,
            venueName = booking.SubVenue?.Venue?.Name,
            escrowStatus = "Settled",
            settledTransactionsCount = settledCount,
            settledTotalAmount = settledAmount > 0 ? settledAmount : booking.DepositAmount,
            checkedInAt = booking.CheckedInAt
        }, "Check-in thành công! Khách hàng đã nhận sân và tiền cọc Escrow đã được giải ngân (Settled) cho chủ sân.");
    }

    public async Task<ApiResponse<CancelRefundResultDto>> CancelTicketWithTieredRefundAsync(int bookingId, int userId)
    {
        var booking = await _unitOfWork.Bookings.GetBookingByIdAndUserAsync(bookingId, userId);
        if (booking == null)
        {
            return ApiResponse<CancelRefundResultDto>.Fail("Không tìm thấy đơn đặt sân của bạn", 404);
        }

        if (booking.Status == "Cancelled")
        {
            return ApiResponse<CancelRefundResultDto>.Fail("Đơn đặt sân này đã được hủy trước đó", 400);
        }

        if (booking.IsCheckedIn || booking.Status == "Completed")
        {
            return ApiResponse<CancelRefundResultDto>.Fail("Vé đã check-in hoàn tất, không thể hủy", 400);
        }

        var firstSlotTimeStr = booking.BookingDetails
            .OrderBy(bd => bd.SlotId)
            .Select(bd => bd.TimeSlot?.StartTime)
            .FirstOrDefault() ?? "18:00";

        if (!TimeOnly.TryParse(firstSlotTimeStr, out var startTime))
        {
            startTime = new TimeOnly(18, 0);
        }

        var matchDateTime = booking.PlayDate.ToDateTime(startTime);
        var now = MatchRules.VietnamNow;
        var hoursBeforeMatch = Math.Round((matchDateTime - now).TotalHours, 1);

        // Chính sách phạt hủy bậc thang (Tiered Cancellation Policy - BR-CANCEL-01..03):
        // >= 4h: Hoàn 100% | 2h - 4h: Hoàn 50% | < 2h: Phạt 100% (0% hoàn)
        int refundPercentage;
        string policyApplied;
        if (hoursBeforeMatch >= 4)
        {
            refundPercentage = 100;
            policyApplied = "Hủy trước >= 4 tiếng: Hoàn 100% tiền cọc về Ví";
        }
        else if (hoursBeforeMatch >= 2)
        {
            refundPercentage = 50;
            policyApplied = "Hủy trước từ 2 - 4 tiếng: Hoàn 50% tiền cọc, phạt 50% bồi thường chủ sân";
        }
        else
        {
            refundPercentage = 0;
            policyApplied = "Hủy sát giờ (< 2 tiếng): Phạt 100% tiền cọc (Không hoàn tiền)";
        }

        int refundAmount = (int)Math.Round(booking.DepositAmount * (refundPercentage / 100.0), MidpointRounding.AwayFromZero);
        int penaltyAmount = booking.DepositAmount - refundAmount;

        booking.Status = "Cancelled";
        foreach (var detail in booking.BookingDetails)
        {
            detail.Status = "Cancelled";
        }

        foreach (var tx in booking.Transactions.Where(t => t.UserId == userId && t.Status == "Holding"))
        {
            tx.Status = refundPercentage > 0 ? "Refunded" : "Settled";
        }

        if (booking.User != null && refundAmount > 0)
        {
            booking.User.WalletBalance += refundAmount;
        }

        // Nếu đơn đặt sân có mở kèo tuyển vãng lai (OpenMatch), hủy kèo và hoàn 100% cho các thành viên vãng lai đã đóng tiền
        if (booking.OpenMatch != null)
        {
            booking.OpenMatch.Status = "Cancelled";
            foreach (var member in booking.OpenMatch.MatchMembers.Where(m => m.UserId.HasValue && m.User != null))
            {
                member.User!.WalletBalance += member.PaidAmount;
                member.PaymentStatus = "Refunded";
                foreach (var mtx in booking.Transactions.Where(t => t.UserId == member.UserId && t.Status == "Holding"))
                {
                    mtx.Status = "Refunded";
                }
            }
        }

        await _unitOfWork.SaveChangesAsync();

        var result = new CancelRefundResultDto
        {
            BookingId = booking.Id,
            BookingCode = booking.BookingCode,
            HoursBeforeMatch = hoursBeforeMatch,
            RefundPercentage = refundPercentage,
            RefundAmount = refundAmount,
            PenaltyAmount = penaltyAmount,
            NewWalletBalance = booking.User?.WalletBalance ?? 0,
            PolicyApplied = policyApplied
        };

        return ApiResponse<CancelRefundResultDto>.Ok(result, $"Hủy vé thành công ({policyApplied}).");
    }
}
