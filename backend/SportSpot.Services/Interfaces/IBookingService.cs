using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IBookingService
{
    Task<ApiResponse<BookingResponseDto>> CreateBookingAsync(CreateBookingRequest request);
    Task<ApiResponse<List<BookingResponseDto>>> GetMyBookingsAsync(int userId);
    Task<ApiResponse<object>> CheckInAsync(CheckInRequest request);
    Task<ApiResponse<CancelRefundResultDto>> CancelBookingAsync(int bookingId, int userId);
}
