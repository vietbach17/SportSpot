using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class SportService : ISportService
{
    private readonly IUnitOfWork _unitOfWork;

    public SportService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<SportDto>>> GetSportsAsync()
    {
        var sports = await _unitOfWork.Sports.GetSportsWithVenuesAsync();
        var result = sports.Select(s => new SportDto
        {
            Id = s.Id,
            Name = s.Name,
            IconUrl = s.IconUrl,
            VenueCount = s.Venues.Count(v => v.IsActive)
        }).ToList();

        return ApiResponse<List<SportDto>>.Ok(result, "Lấy danh sách môn thể thao thành công");
    }
}
