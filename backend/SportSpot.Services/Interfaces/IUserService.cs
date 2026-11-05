using SportSpot.Services.DTOs;

namespace SportSpot.Services.Interfaces;

public interface IUserService
{
    Task<ApiResponse<UserProfileDto>> GetMyProfileAsync(int userId);
    Task<ApiResponse<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileRequest request);
    Task<ApiResponse<List<UserSkillDto>>> GetUserSkillsAsync(int userId);
    Task<ApiResponse<List<UserSkillDto>>> SaveUserSkillsAsync(int userId, UpdateUserSkillsRequest request);
}
