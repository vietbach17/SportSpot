using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface ISportService
{
    Task<ApiResponse<List<SportDto>>> GetSportsAsync();
}
