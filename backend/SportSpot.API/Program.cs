using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SportSpot.API.Data;
using SportSpot.API.Middlewares;
using SportSpot.API.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình EF Core với PostgreSQL (Supabase)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<SportSpotDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. Cấu hình MemoryCache cho OTP (TTL 120s)
builder.Services.AddMemoryCache();

// 3. Đăng ký JwtService
builder.Services.AddScoped<IJwtService, JwtService>();

// 4. Cấu hình JWT Bearer Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "SportSpot_PRM393_Secret_Key_Super_Secure_2026_Key_Must_Be_Long_Enough!";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "SportSpotAPI",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "SportSpotMobileApp",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

// 5. Cấu hình CORS để ứng dụng di động Flutter có thể gọi API thuận tiện
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 6. Cấu hình Controllers và tuần tự hóa JSON
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

// 7. Cấu hình Swagger / OpenAPI hỗ trợ nút Authorize JWT
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SportSpot API",
        Version = "v1",
        Description = "Backend API cho đồ án SportSpot (PRM393) - Hỗ trợ JWT Auth & Dev Bypass Header X-Mock-User-Id"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập Token theo cú pháp: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 8. Middleware Pipeline
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SportSpot API v1");
    c.RoutePrefix = string.Empty; // Mở Swagger trực tiếp tại http://localhost:5000/
});

app.UseCors("AllowAll");

// Middleware hỗ trợ kiểm thử nội bộ: Cho phép gửi header X-Mock-User-Id
app.UseMiddleware<DevBypassAuthMiddleware>();

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.MapControllers();

app.Run();
