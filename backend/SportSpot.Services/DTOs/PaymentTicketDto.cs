namespace SportSpot.Services.DTOs;

public class CreatePaymentIntentRequest
{
    public int BookingId { get; set; }
    public int UserId { get; set; }
    public int Amount { get; set; }
    public string PaymentGateway { get; set; } = "VNPay";
}

public class PaymentIntentResponseDto
{
    public string TransactionCode { get; set; } = string.Empty;
    public string PaymentUrl { get; set; } = string.Empty;
    public string EscrowStatus { get; set; } = "Holding";
}

public class PaymentWebhookRequest
{
    public string TransactionCode { get; set; } = string.Empty;
    public bool IsSuccess { get; set; } = true;
}

public class CancelRefundResultDto
{
    public int BookingId { get; set; }
    public string BookingCode { get; set; } = string.Empty;
    public double HoursBeforeMatch { get; set; }
    public int RefundPercentage { get; set; }
    public int RefundAmount { get; set; }
    public int PenaltyAmount { get; set; }
    public int NewWalletBalance { get; set; }
    public string PolicyApplied { get; set; } = string.Empty;
}
