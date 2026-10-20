using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IMatchService
{
    Task<ApiResponse<List<OpenMatchDto>>> GetOpenMatchesAsync(int? sportId, string? district);
    Task<ApiResponse<object>> JoinMatchAsync(int matchId, JoinMatchRequest request);
    Task<ApiResponse<object>> AssignWalkInAtDeskAsync(int matchId);
    Task<ApiResponse<object>> StopRecruitingAsync(int matchId, int hostUserId);
    Task<ApiResponse<object>> LeaveMatchAsync(int matchId, int userId);
}
