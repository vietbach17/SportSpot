using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportSpot.Services.DTOs;
using SportSpot.Services.Implementations;

namespace SportSpot.API.Controllers;

public class VenueImageUploadRequest
{
    public IFormFile File { get; set; } = null!;
}

[ApiController, Authorize, Route("api/venue-applications")]
public class VenueApplicationsController(VenueApplicationService service) : ControllerBase
{
    private int UserId => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;
    [HttpGet("mine")] public async Task<IActionResult> Mine() => Respond(await service.Mine(UserId));
    [HttpGet("images")] public async Task<IActionResult> Images() => Respond(await service.UnusedImages(UserId));
    [HttpPost] public async Task<IActionResult> Submit(SubmitVenueRequest request) => Respond(await service.Submit(UserId, request));
    [HttpPut("{id:int}")] public async Task<IActionResult> Resubmit(int id, SubmitVenueRequest request) => Respond(await service.Submit(UserId, request, id));
    [HttpPost("images"), RequestSizeLimit(9 * 1024 * 1024)]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Upload([FromForm] VenueImageUploadRequest request, CancellationToken cancellationToken)
    {
        var file = request?.File;
        if (file == null || file.Length is < 12 or > 8388608) return BadRequest(ApiResponse<object>.Fail("Chọn ảnh JPG/PNG/WebP tối đa 8 MB"));
        using var stream = new MemoryStream();
        await file.CopyToAsync(stream, cancellationToken);
        return Respond(await service.Upload(UserId, stream.ToArray(), cancellationToken));
    }
    private ObjectResult Respond<T>(ApiResponse<T> result) => StatusCode(result.StatusCode, result);
}
