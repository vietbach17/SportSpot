using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class CloudinaryImageStorage(HttpClient client, IConfiguration config) : IVenueImageStorage
{
    public async Task<StoredVenueImage> UploadAsync(byte[] bytes, string contentType, CancellationToken cancellationToken = default)
    {
        var cloud = Environment.GetEnvironmentVariable("CLOUDINARY_CLOUD_NAME")
            ?? Environment.GetEnvironmentVariable("NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME") ?? config["Cloudinary:CloudName"];
        var preset = Environment.GetEnvironmentVariable("CLOUDINARY_UPLOAD_PRESET")
            ?? Environment.GetEnvironmentVariable("NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET") ?? config["Cloudinary:UploadPreset"];
        if (string.IsNullOrWhiteSpace(cloud) || !Regex.IsMatch(cloud, @"^[a-zA-Z0-9_-]+$") || string.IsNullOrWhiteSpace(preset))
            throw new InvalidOperationException("Chưa cấu hình Cloudinary cloud name và unsigned upload preset trên backend.");
        using var form = new MultipartFormDataContent();
        using var file = new ByteArrayContent(bytes);
        file.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        var extension = contentType == "image/png" ? "png" : contentType == "image/webp" ? "webp" : "jpg";
        form.Add(file, "file", $"venue-{Guid.NewGuid():N}.{extension}");
        form.Add(new StringContent(preset), "upload_preset");
        form.Add(new StringContent("sportspot/venues"), "folder");
        using var response = await client.PostAsync($"https://api.cloudinary.com/v1_1/{cloud}/image/upload", form, cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException(response.StatusCode is System.Net.HttpStatusCode.BadRequest or System.Net.HttpStatusCode.Unauthorized
                ? "Cloudinary từ chối upload. Kiểm tra preset đã bật Unsigned và cho phép ảnh JPG/PNG/WebP."
                : "Không tải ảnh lên Cloudinary được. Vui lòng thử lại sau.");
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
        var url = json.RootElement.GetProperty("secure_url").GetString()!;
        var publicId = json.RootElement.GetProperty("public_id").GetString()!;
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme != "https" || uri.Host != "res.cloudinary.com")
            throw new HttpRequestException("Cloudinary trả về đường dẫn ảnh không hợp lệ.");
        return new(url, publicId);
    }
}
