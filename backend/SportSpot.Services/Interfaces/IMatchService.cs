using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IMatchService
{
    Task<ApiResponse<object>> GetMyTicketAsync(int matchId, int userId);
    Task<ApiResponse<OpenMatchDto>> GetMatchAsync(int id);
    Task<ApiResponse<OpenMatchDto>> CreateMatchAsync(int userId, CreateMatchRequest request);
    Task<ApiResponse<List<OpenMatchDto>>> GetStaffMatchesAsync(int staffId);
    Task<ApiResponse<List<OpenMatchDto>>> GetOpenMatchesAsync(int? sportId, string? district);
    Task<ApiResponse<object>> JoinMatchAsync(int matchId, JoinMatchRequest request);
    Task<ApiResponse<object>> AssignWalkInAtDeskAsync(int matchId, int staffId);
    Task<ApiResponse<object>> StopRecruitingAsync(int matchId, int hostUserId);
    Task<ApiResponse<object>> LeaveMatchAsync(int matchId, int userId);
}
