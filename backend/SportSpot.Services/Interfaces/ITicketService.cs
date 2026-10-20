using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface ITicketService
{
    Task<ApiResponse<List<BookingResponseDto>>> GetMyTicketsAsync(int userId);
    Task<ApiResponse<object>> VerifyQrAndSettleEscrowAsync(CheckInRequest request);
    Task<ApiResponse<CancelRefundResultDto>> CancelTicketWithTieredRefundAsync(int bookingId, int userId);
}
