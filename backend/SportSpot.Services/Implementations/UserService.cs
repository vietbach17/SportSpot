using Microsoft.EntityFrameworkCore;
using SportSpot.Data.Context;
using SportSpot.Data.Entities;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Services.DTOs;
using SportSpot.Services.Interfaces;

namespace SportSpot.Services.Implementations;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly SportSpotDbContext _context;

    public UserService(IUnitOfWork unitOfWork, SportSpotDbContext context)
    {
        _unitOfWork = unitOfWork;
        _context = context;
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

    public async Task<ApiResponse<List<UserSkillDto>>> GetUserSkillsAsync(int userId)
    {
        if (userId <= 0)
        {
            return ApiResponse<List<UserSkillDto>>.Fail("Không xác định được danh tính người dùng", 401);
        }

        var skills = await _context.UserSkills
            .Include(us => us.Sport)
            .Where(us => us.UserId == userId)
            .OrderBy(us => us.SportId)
            .Select(us => new UserSkillDto
            {
                Id = us.Id,
                UserId = us.UserId,
                SportId = us.SportId,
                SportName = us.Sport != null ? us.Sport.Name : string.Empty,
                SkillLevel = us.SkillLevel,
                RatingScore = us.RatingScore,
                IsVerified = us.IsVerified,
                VerifiedBy = us.VerifiedBy,
                UpdatedAt = us.UpdatedAt
            })
            .ToListAsync();

        return ApiResponse<List<UserSkillDto>>.Ok(skills, "Lấy danh sách kỹ năng thành công");
    }

    public async Task<ApiResponse<List<UserSkillDto>>> SaveUserSkillsAsync(int userId, UpdateUserSkillsRequest request)
    {
        if (userId <= 0)
        {
            return ApiResponse<List<UserSkillDto>>.Fail("Không xác định được danh tính người dùng", 401);
        }

        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return ApiResponse<List<UserSkillDto>>.Fail("Không tìm thấy thông tin người dùng", 404);
        }

        var allSports = await _context.Sports.ToListAsync();

        var selectedSportIds = new HashSet<int>();
        var updatedSportNames = new List<string>();

        foreach (var item in request.Skills)
        {
            Sport? matchedSport = null;
            if (item.SportId.HasValue && item.SportId.Value > 0)
            {
                matchedSport = allSports.FirstOrDefault(s => s.Id == item.SportId.Value);
            }
            if (matchedSport == null && !string.IsNullOrWhiteSpace(item.SportName))
            {
                var cleanName = item.SportName.Trim().ToLower();
                matchedSport = allSports.FirstOrDefault(s =>
                    s.Name.ToLower() == cleanName ||
                    cleanName.Contains(s.Name.ToLower()) ||
                    s.Name.ToLower().Contains(cleanName));
            }

            if (matchedSport == null)
            {
                var sportName = string.IsNullOrWhiteSpace(item.SportName) ? "Thể thao" : item.SportName.Trim();
                matchedSport = new Sport
                {
                    Name = sportName,
                    IconUrl = "https://cdn-icons-png.flaticon.com/512/2906/2906478.png"
                };
                _context.Sports.Add(matchedSport);
                await _context.SaveChangesAsync();
                allSports.Add(matchedSport);
            }

            selectedSportIds.Add(matchedSport.Id);
            if (!updatedSportNames.Contains(matchedSport.Name))
            {
                updatedSportNames.Add(matchedSport.Name);
            }

            var existingSkill = await _context.UserSkills
                .FirstOrDefaultAsync(us => us.UserId == userId && us.SportId == matchedSport.Id);

            if (existingSkill != null)
            {
                existingSkill.SkillLevel = string.IsNullOrWhiteSpace(item.SkillLevel) ? "Phong trào" : item.SkillLevel.Trim();
                existingSkill.RatingScore = item.RatingScore > 0 ? item.RatingScore : 3.5m;
                existingSkill.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                var newSkill = new UserSkill
                {
                    UserId = userId,
                    SportId = matchedSport.Id,
                    SkillLevel = string.IsNullOrWhiteSpace(item.SkillLevel) ? "Phong trào" : item.SkillLevel.Trim(),
                    RatingScore = item.RatingScore > 0 ? item.RatingScore : 3.5m,
                    IsVerified = false,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UserSkills.Add(newSkill);
            }
        }

        if (updatedSportNames.Any())
        {
            user.FavoriteSports = string.Join(",", updatedSportNames);
            _unitOfWork.Users.Update(user);
        }

        if (request.Skills.Any())
        {
            var skillsToRemove = await _context.UserSkills
                .Where(us => us.UserId == userId && !selectedSportIds.Contains(us.SportId))
                .ToListAsync();
            if (skillsToRemove.Any())
            {
                _context.UserSkills.RemoveRange(skillsToRemove);
            }
        }

        await _context.SaveChangesAsync();

        return await GetUserSkillsAsync(userId);
    }
}
