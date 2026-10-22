using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IPaymentService
{
    Task<ApiResponse<PaymentIntentResponseDto>> CreatePaymentIntentAsync(CreatePaymentIntentRequest request);
    Task<ApiResponse<object>> ProcessWebhookAsync(PaymentWebhookRequest request);
    Task<ApiResponse<BookingResponseDto>> MockInstantPayAsync(string bookingCode);
    Task<ApiResponse<WalletAndHistoryDto>> GetUserTransactionsAsync(int userId);
}
