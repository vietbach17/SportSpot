using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;

    public UserService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<UserProfileDto>> GetMyProfileAsync(int userId)
    {
        if (userId <= 0)
        {
            return ApiResponse<UserProfileDto>.Fail("Không xác định được danh tính người dùng", 401);
        }

        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return ApiResponse<UserProfileDto>.Fail("Không tìm thấy thông tin người dùng", 404);
        }

        var profile = new UserProfileDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AvatarUrl = user.AvatarUrl,
            IsFindMatchEnabled = user.IsFindMatchEnabled,
            FavoriteSports = user.FavoriteSports
        };

        return ApiResponse<UserProfileDto>.Ok(profile, "Lấy thông tin người dùng thành công");
    }

    public async Task<ApiResponse<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileRequest request)
    {
        if (userId <= 0)
        {
            return ApiResponse<UserProfileDto>.Fail("Không xác định được danh tính người dùng", 401);
        }

        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return ApiResponse<UserProfileDto>.Fail("Không tìm thấy thông tin người dùng", 404);
        }

        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName.Trim();
        }

        if (request.Email != null)
        {
            user.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        }

        if (request.IsFindMatchEnabled.HasValue)
        {
            user.IsFindMatchEnabled = request.IsFindMatchEnabled.Value;
        }

        if (request.FavoriteSports != null)
        {
            user.FavoriteSports = request.FavoriteSports.Trim();
        }

        if (request.AvatarUrl != null)
        {
            user.AvatarUrl = request.AvatarUrl.Trim();
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync();

        var updatedProfile = new UserProfileDto
        {
            UserId = user.Id,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Email = user.Email,
            Role = user.Role,
            WalletBalance = user.WalletBalance,
            AvatarUrl = user.AvatarUrl,
            IsFindMatchEnabled = user.IsFindMatchEnabled,
            FavoriteSports = user.FavoriteSports
        };

        return ApiResponse<UserProfileDto>.Ok(updatedProfile, "Cập nhật hồ sơ cá nhân thành công");
    }
}
