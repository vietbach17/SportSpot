using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Helpers;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class BookingService : IBookingService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ITicketService _ticketService;

    public BookingService(IUnitOfWork unitOfWork, ITicketService ticketService)
    {
        _unitOfWork = unitOfWork;
        _ticketService = ticketService;
    }

    public async Task<ApiResponse<BookingResponseDto>> CreateBookingAsync(CreateBookingRequest request)
    {
        if (request.IsOpenMatch && (!MatchRules.ValidPlayers(request.TotalExpectedPlayers ?? 0, request.NeededPlayers ?? 0)
            || request.SkillLevel is not ("Cơ bản" or "Trung bình")))
            return ApiResponse<BookingResponseDto>.Fail("Số người tuyển phải lớn hơn 0, nhỏ hơn tổng số người; trình độ không hợp lệ");
        if (request.SlotIds == null || request.SlotIds.Count == 0)
        {
            return ApiResponse<BookingResponseDto>.Fail("Vui lòng chọn ít nhất 1 khung giờ");
        }

        if (request.SlotIds.Count > 3)
        {
            return ApiResponse<BookingResponseDto>.Fail("Chỉ được chọn tối đa 3 slot (3 tiếng) cho một đơn đặt");
        }

        var subVenue = await _unitOfWork.Bookings.GetActiveSubVenueWithVenueAsync(request.SubVenueId);
        if (subVenue == null || subVenue.Venue == null)
        {
            return ApiResponse<BookingResponseDto>.Fail("Không tìm thấy sân con hoặc sân đang bảo trì", 404);
        }

        var selectedSlots = await _unitOfWork.Bookings.GetTimeSlotsByIdsAsync(request.SlotIds);
        if (selectedSlots.Count != request.SlotIds.Count)
        {
            return ApiResponse<BookingResponseDto>.Fail("Một số khung giờ được chọn không hợp lệ");
        }

        if (request.IsOpenMatch && (request.PlayDate < DateOnly.FromDateTime(MatchRules.VietnamNow)
            || request.PlayDate > DateOnly.FromDateTime(MatchRules.VietnamNow).AddDays(6)
            || !TimeOnly.TryParse(selectedSlots[0].StartTime, out var startTime)
            || request.PlayDate.ToDateTime(startTime) <= MatchRules.VietnamNow))
            return ApiResponse<BookingResponseDto>.Fail("Kèo phải diễn ra trong 7 ngày tới và chưa bắt đầu");

        for (int i = 0; i < selectedSlots.Count - 1; i++)
        {
            if (selectedSlots[i].EndTime != selectedSlots[i + 1].StartTime)
            {
                return ApiResponse<BookingResponseDto>.Fail("Các khung giờ được chọn bắt buộc phải liên tiếp nhau");
            }
        }

        int courtPrice = 0;
        foreach (var slot in selectedSlots)
        {
            courtPrice += slot.IsPeak ? subVenue.Venue.PeakPrice : subVenue.Venue.BasePrice;
        }

        int servicesPrice = 0;
        var bookingServices = new List<SportSpot.Data.Entities.BookingService>();
        if (request.Services != null && request.Services.Count > 0)
        {
            var serviceIds = request.Services.Select(s => s.ServiceId).ToList();
            var availableServices = await _unitOfWork.Bookings.GetVenueServicesDictionaryAsync(subVenue.VenueId, serviceIds);

            foreach (var reqService in request.Services)
            {
                if (availableServices.TryGetValue(reqService.ServiceId, out var svc))
                {
                    var itemTotal = svc.Price * reqService.Quantity;
                    servicesPrice += itemTotal;
                    bookingServices.Add(new SportSpot.Data.Entities.BookingService
                    {
                        ServiceId = svc.Id,
                        Quantity = reqService.Quantity,
                        Price = svc.Price
                    });
                }
            }
        }

        int totalPrice = courtPrice + servicesPrice;
        int depositAmount = request.DepositPercentage >= 100 ? totalPrice : (int)Math.Round(totalPrice * 0.3);
        int remainingBalance = totalPrice - depositAmount;
        var bookingCode = $"SP-{Random.Shared.Next(100000, 999999)}";

        var booking = new Booking
        {
            BookingCode = bookingCode,
            UserId = request.UserId,
            SubVenueId = request.SubVenueId,
            PlayDate = request.PlayDate,
            CourtPrice = courtPrice,
            ServicesPrice = servicesPrice,
            TotalPrice = totalPrice,
            DepositAmount = depositAmount,
            RemainingBalance = remainingBalance,
            BookingType = request.IsOpenMatch ? "OpenMatch" : "Standard",
            Status = "Upcoming",
            IsCheckedIn = false,
            CreatedAt = DateTime.UtcNow
        };

        foreach (var slot in selectedSlots)
        {
            int slotPrice = slot.IsPeak ? subVenue.Venue.PeakPrice : subVenue.Venue.BasePrice;
            booking.BookingDetails.Add(new BookingDetail
            {
                SubVenueId = request.SubVenueId,
                PlayDate = request.PlayDate,
                SlotId = slot.Id,
                Price = slotPrice,
                Status = "Upcoming"
            });
        }

        foreach (var bs in bookingServices)
        {
            booking.BookingServices.Add(bs);
        }

        if (request.IsOpenMatch && request.TotalExpectedPlayers.HasValue && request.NeededPlayers.HasValue)
        {
            int totalExpected = request.TotalExpectedPlayers.Value;
            int needed = request.NeededPlayers.Value;
            int costPerPerson = MatchRules.SplitCost(courtPrice, totalExpected);

            booking.OpenMatch = new OpenMatch
            {
                HostUserId = request.UserId,
                TotalExpectedPlayers = totalExpected,
                NeededPlayers = needed,
                CurrentJoinedPlayers = 0,
                CostPerPerson = costPerPerson,
                SkillLevel = request.SkillLevel,
                Status = "Open",
                CreatedAt = DateTime.UtcNow
            };
        }

        booking.Transactions.Add(new Transaction
        {
            UserId = request.UserId,
            Amount = depositAmount,
            PaymentGateway = request.PaymentGateway,
            TransactionCode = $"TXN-{Guid.NewGuid():N}"[..20].ToUpper(),
            Status = "Holding",
            CreatedAt = DateTime.UtcNow
        });

        // Concurrency lock using Serializable Isolation Level Transaction
        using var transaction = await _unitOfWork.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
        try
        {
            var conflictedSlots = await _unitOfWork.Bookings.GetConflictedSlotsAsync(
                request.SubVenueId, request.PlayDate, request.SlotIds);

            if (conflictedSlots.Count > 0)
            {
                await transaction.RollbackAsync();
                var conflictSlotNames = string.Join(", ", conflictedSlots.Select(c => $"{c.TimeSlot?.StartTime}-{c.TimeSlot?.EndTime}"));
                return ApiResponse<BookingResponseDto>.Fail(
                    $"Rất tiếc! Khung giờ ({conflictSlotNames}) vừa có người khác đặt trước. Vui lòng chọn khung giờ khác.", 409);
            }

            await _unitOfWork.Bookings.AddAsync(booking);
            await _unitOfWork.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync();
            return ApiResponse<BookingResponseDto>.Fail(
                "Đã xảy ra tranh chấp đặt sân cùng thời điểm. Vui lòng thử lại.", 409);
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }

        var fullQrPayload = QrChecksumHelper.BuildSignedQrPayload(booking.BookingCode, booking.UserId, "Host");

        var response = new BookingResponseDto
        {
            BookingId = booking.Id,
            BookingCode = booking.BookingCode,
            VenueName = subVenue.Venue.Name,
            SubVenueName = subVenue.Name,
            SportName = subVenue.Venue.Sport?.Name ?? string.Empty,
            Address = subVenue.Venue.Address,
            PlayDate = booking.PlayDate,
            TimeSlots = selectedSlots.Select(s => $"{s.StartTime}-{s.EndTime}").ToList(),
            CourtPrice = booking.CourtPrice,
            ServicesPrice = booking.ServicesPrice,
            TotalPrice = booking.TotalPrice,
            DepositAmount = booking.DepositAmount,
            RemainingBalance = booking.RemainingBalance,
            Status = booking.Status,
            QrPayload = fullQrPayload,
            IsCheckedIn = booking.IsCheckedIn
        };

        return ApiResponse<BookingResponseDto>.Ok(response, "Đặt sân thành công");
    }

    public Task<ApiResponse<List<BookingResponseDto>>> GetMyBookingsAsync(int userId)
        => _ticketService.GetMyTicketsAsync(userId);

    public Task<ApiResponse<object>> CheckInAsync(CheckInRequest request)
        => _ticketService.VerifyQrAndSettleEscrowAsync(request);

    public Task<ApiResponse<CancelRefundResultDto>> CancelBookingAsync(int bookingId, int userId)
        => _ticketService.CancelTicketWithTieredRefundAsync(bookingId, userId);
}
