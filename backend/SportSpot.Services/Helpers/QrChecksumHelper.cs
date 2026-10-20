using System.Security.Cryptography;
using System.Text;

namespace SportSpot.Services.Helpers;

public static class QrChecksumHelper
{
    private const string SecretSalt = "_SPORTSPOT_SECRET_KEY";

    public static string GenerateShortChecksum(string input)
    {
        using var sha256 = SHA256.Create();
        var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input + SecretSalt));
        return Convert.ToHexString(bytes)[..8];
    }

    public static string BuildSignedQrPayload(string bookingCode, int userId, string role)
    {
        var raw = $"SPORTSPOT|{bookingCode}|{userId}|{role}";
        var checksum = GenerateShortChecksum(raw);
        return $"{raw}|{checksum}";
    }

    public static bool ValidateSignedQrPayload(string qrPayload, out string bookingCode, out int userId, out string role)
    {
        bookingCode = string.Empty;
        userId = 0;
        role = string.Empty;

        if (string.IsNullOrWhiteSpace(qrPayload)) return false;

        var parts = qrPayload.Split('|');
        if (parts.Length < 5 || parts[0] != "SPORTSPOT") return false;

        var expectedRaw = $"{parts[0]}|{parts[1]}|{parts[2]}|{parts[3]}";
        var providedChecksum = parts[4];

        if (GenerateShortChecksum(expectedRaw) != providedChecksum) return false;

        bookingCode = parts[1];
        int.TryParse(parts[2], out userId);
        role = parts[3];
        return true;
    }
}
