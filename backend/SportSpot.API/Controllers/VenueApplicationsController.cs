using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Implementations;
using SportSpot.Services.Helpers;

namespace SportSpot.API.Controllers;

public class VenueImageUploadRequest
{
    public IFormFile File { get; set; } = null!;
}

[ApiController, Authorize, Route("api/venue-applications")]
public class VenueApplicationsController(VenueApplicationService service, IHttpClientFactory clients) : ControllerBase
{
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    [HttpGet("slot-templates")]
    public async Task<IActionResult> SlotTemplates() => Respond(await service.SlotTemplates());

    [HttpGet("mine")]
    public async Task<IActionResult> Mine() => Respond(await service.Mine(UserId));

    [HttpGet("images")]
    public async Task<IActionResult> Images() => Respond(await service.UnusedImages(UserId));

    [HttpPost("images/link")]
    public async Task<IActionResult> ImageLink(VenueImageLinkRequest request) => Respond(await service.AddImageLink(UserId, request.Url));

    [HttpPost("map-location")]
    public async Task<IActionResult> MapLocation(VenueMapsLinkRequest request, CancellationToken cancellationToken)
    {
        if (!Uri.TryCreate(request.Url.Trim(), UriKind.Absolute, out var uri) || !GoogleMapsLinkHelper.IsMapsUrl(uri))
            return BadRequest(ApiResponse<object>.Fail("Dán link Google Maps hợp lệ (https://maps.app.goo.gl/... hoặc https://www.google.com/maps/...)"));
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(10));
        try
        {
            var client = clients.CreateClient("GoogleMapsLinks");
            for (var i = 0; i < 6; i++)
            {
                var location = GoogleMapsLinkHelper.Parse(uri.AbsoluteUri);
                if (location.HasValue) return Ok(ApiResponse<VenueLocationDto>.Ok(new(location.Value.Latitude, location.Value.Longitude)));
                using var response = await client.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
                if ((int)response.StatusCode is < 300 or >= 400 || response.Headers.Location == null) break;
                var next = new Uri(uri, response.Headers.Location);
                if (!GoogleMapsLinkHelper.IsMapsUrl(next)) break;
                uri = next;
            }
        }
        catch (HttpRequestException) { }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested) { }
        return BadRequest(ApiResponse<object>.Fail("Chưa lấy được vị trí. Hãy mở đúng địa điểm trên Google Maps, chọn Chia sẻ → Sao chép liên kết rồi dán lại."));
    }

    [HttpPost]
    public async Task<IActionResult> Submit([FromBody] SubmitVenueRequest request) => Respond(await service.Submit(UserId, request));

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Resubmit(int id, [FromBody] SubmitVenueRequest request) => Respond(await service.Submit(UserId, request, id));

    [HttpPost("images"), RequestSizeLimit(9 * 1024 * 1024)]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Upload([FromForm] VenueImageUploadRequest request, CancellationToken cancellationToken)
    {
        var file = request?.File;
        if (file == null || file.Length is < 12 or > 8388608)
            return BadRequest(ApiResponse<object>.Fail("Chọn ảnh JPG/PNG/WebP tối đa 8 MB"));
        using var stream = new MemoryStream();
        await file.CopyToAsync(stream, cancellationToken);
        return Respond(await service.Upload(UserId, stream.ToArray(), cancellationToken));
    }

    private ObjectResult Respond<T>(ApiResponse<T> result) => StatusCode(result.StatusCode, result);
}
