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
        var bookings = await _unitOfWork.Bookings.GetUserBookingsWithDetailsAsync(userId);

        var result = bookings.Select(b =>
        {
            var qrPayload = QrChecksumHelper.BuildSignedQrPayload(b.BookingCode, b.UserId, "Host");

            return new BookingResponseDto
            {
                BookingId = b.Id,
                BookingCode = b.BookingCode,
                VenueName = b.SubVenue?.Venue?.Name ?? string.Empty,
                SubVenueName = b.SubVenue?.Name ?? string.Empty,
                SportName = b.SubVenue?.Venue?.Sport?.Name ?? string.Empty,
                Address = b.SubVenue?.Venue?.Address ?? string.Empty,
                PlayDate = b.PlayDate,
                TimeSlots = b.BookingDetails
                    .OrderBy(bd => bd.SlotId)
                    .Select(bd => $"{bd.TimeSlot?.StartTime}-{bd.TimeSlot?.EndTime}")
                    .ToList(),
                CourtPrice = b.CourtPrice,
                ServicesPrice = b.ServicesPrice,
                TotalPrice = b.TotalPrice,
                DepositAmount = b.DepositAmount,
                RemainingBalance = b.RemainingBalance,
                Status = b.Status,
                QrPayload = qrPayload,
                IsCheckedIn = b.IsCheckedIn
            };
        }).ToList();

        return ApiResponse<List<BookingResponseDto>>.Ok(result, "Lấy danh sách vé thành công");
    }

    public async Task<ApiResponse<object>> VerifyQrAndSettleEscrowAsync(CheckInRequest request)
    {
        if (!QrChecksumHelper.ValidateSignedQrPayload(
            request.QrPayload, out var bookingCode, out var scannedUserId, out var role))
        {
            return ApiResponse<object>.Fail("Mã QR không hợp lệ hoặc chữ ký bảo mật (Checksum) đã bị chỉnh sửa");
        }

        var booking = await _unitOfWork.Bookings.GetBookingByCodeWithDetailsAsync(bookingCode);
        if (booking == null)
        {
            return ApiResponse<object>.Fail("Không tìm thấy thông tin đơn đặt sân", 404);
        }

        if (booking.IsCheckedIn && role == "Host")
        {
            return ApiResponse<object>.Fail($"Vé này đã được check-in lúc {booking.CheckedInAt:HH:mm dd/MM/yyyy}");
        }

        booking.IsCheckedIn = true;
        booking.CheckedInAt = DateTime.UtcNow;
        booking.Status = "Completed";

        // Giải ngân Escrow: Chuyển toàn bộ các giao dịch Holding của đơn này sang Settled (BR-PAY-03)
        foreach (var tx in booking.Transactions.Where(t => t.Status == "Holding"))
        {
            tx.Status = "Settled";
        }

        await _unitOfWork.SaveChangesAsync();

        return ApiResponse<object>.Ok(new
        {
            bookingCode = booking.BookingCode,
            customerName = booking.User?.FullName,
            role,
            subVenueName = booking.SubVenue?.Name,
            venueName = booking.SubVenue?.Venue?.Name,
            escrowStatus = "Settled",
            checkedInAt = booking.CheckedInAt
        }, "Check-in thành công! Khách hàng đã nhận sân và tiền cọc Escrow đã được giải ngân (Settled) cho chủ sân.");
    }

    public async Task<ApiResponse<CancelRefundResultDto>> CancelTicketWithTieredRefundAsync(int bookingId, int userId)
    {
        var booking = await _unitOfWork.Bookings.GetBookingByIdAndUserAsync(bookingId, userId);
        if (booking == null)
        {
            return ApiResponse<CancelRefundResultDto>.Fail("Không tìm thấy đơn đặt sân", 404);
        }

        if (booking.Status == "Cancelled")
        {
            return ApiResponse<CancelRefundResultDto>.Fail("Đơn đặt sân này đã được hủy trước đó");
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
        var hoursBeforeMatch = Math.Round((matchDateTime - DateTime.Now).TotalHours, 1);

        // Chính sách phạt hủy bậc thang (Tiered Cancellation Policy):
        // >= 4h: Hoàn 100% | 2h - 4h: Hoàn 50% | < 2h: Phạt 100% (0% hoàn)
        int refundPercentage;
        string policyApplied;
        if (hoursBeforeMatch >= 4)
        {
            refundPercentage = 100;
            policyApplied = "Hủy trước >= 4 tiếng: Hoàn 100% tiền cọc";
        }
        else if (hoursBeforeMatch >= 2)
        {
            refundPercentage = 50;
            policyApplied = "Hủy trước từ 2 - 4 tiếng: Hoàn 50% tiền cọc, phạt 50% bồi thường chủ sân";
        }
        else
        {
            refundPercentage = 0;
            policyApplied = "Hủy sát giờ (< 2 tiếng): Phạt 100% tiền cọc";
        }

        int refundAmount = (int)Math.Round(booking.DepositAmount * (refundPercentage / 100.0));
        int penaltyAmount = booking.DepositAmount - refundAmount;

        booking.Status = "Cancelled";
        foreach (var detail in booking.BookingDetails)
        {
            detail.Status = "Cancelled";
        }

        foreach (var tx in booking.Transactions.Where(t => t.Status == "Holding"))
        {
            tx.Status = refundPercentage > 0 ? "Refunded" : "Settled";
        }

        if (booking.User != null && refundAmount > 0)
        {
            booking.User.WalletBalance += refundAmount;
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
