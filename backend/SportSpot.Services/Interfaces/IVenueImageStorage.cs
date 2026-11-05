namespace SportSpot.Services.Interfaces;

public record StoredVenueImage(string Url, string PublicId);
public interface IVenueImageStorage
{
    Task<StoredVenueImage> UploadAsync(byte[] bytes, string contentType, CancellationToken cancellationToken = default);
}
