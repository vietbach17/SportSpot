using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SportSpot.API.Models;

namespace SportSpot.API.Services;

public interface IJwtService
{
    string GenerateToken(User user);
}

public class JwtService : IJwtService
{
    private readonly IConfiguration _config;

    public JwtService(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateToken(User user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _config["Jwt:Key"] ?? "SportSpot_PRM393_Secret_Key_Super_Secure_2026_Key_Must_Be_Long_Enough!"));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.MobilePhone, user.PhoneNumber),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Role)
        };

        if (!string.IsNullOrWhiteSpace(user.Email))
        {
            claims.Add(new(ClaimTypes.Email, user.Email));
        }

        var expiryDays = int.TryParse(_config["Jwt:ExpiryDays"], out var days) ? days : 30;

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"] ?? "SportSpotAPI",
            audience: _config["Jwt:Audience"] ?? "SportSpotMobileApp",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(expiryDays),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
