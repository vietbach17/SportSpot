using PayOS.Models.Webhooks;
using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IPaymentService
{
    Task<ApiResponse<PaymentIntentResponseDto>> CreatePaymentIntentAsync(CreatePaymentIntentRequest request);
    Task<ApiResponse<object>> ProcessWebhookAsync(PaymentWebhookRequest request);
    Task<ApiResponse<object>> ProcessPayOSWebhookAsync(Webhook webhook);
    Task<ApiResponse<string>> ConfirmPayOSWebhookUrlAsync(string webhookUrl);
    Task<ApiResponse<BookingResponseDto>> MockInstantPayAsync(string bookingCode);
    Task<ApiResponse<WalletAndHistoryDto>> GetUserTransactionsAsync(int userId);
    Task<ApiResponse<WalletAndHistoryDto>> TopUpWalletAsync(TopUpWalletRequest request);
    Task<ApiResponse<WalletAndHistoryDto>> WithdrawWalletAsync(WithdrawWalletRequest request);
}
