using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SportSpot.API.Data;
using SportSpot.API.Middlewares;
using SportSpot.API.Models;
using SportSpot.API.Services;

// Nạp các biến môi trường từ file .env (nếu có)
DotNetEnv.Env.TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình EF Core: Ưu tiên lấy từ file .env, sau đó mới đến appsettings.json
var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING");
if (string.IsNullOrWhiteSpace(connectionString))
{
    connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
}

var isSupabaseConfigured = !string.IsNullOrWhiteSpace(connectionString) && 
                           !connectionString.Contains("your-project") &&
                           connectionString.Contains("Host=");

builder.Services.AddDbContext<SportSpotDbContext>(options =>
{
    if (isSupabaseConfigured)
    {
        options.UseNpgsql(connectionString);
    }
    else
    {
        // Chế độ Dev/Test cục bộ không cần mạng hay Supabase
        options.UseSqlite("Data Source=sportspot_dev.db");
    }
});

// 2. Cấu hình MemoryCache cho OTP (TTL 120s)
builder.Services.AddMemoryCache();

// 3. Đăng ký JwtService
builder.Services.AddScoped<IJwtService, JwtService>();

// 4. Cấu hình JWT Bearer Authentication (Ưu tiên đọc từ .env)
var jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") 
    ?? builder.Configuration["Jwt:Key"] 
    ?? "SportSpot_PRM393_Secret_Key_Super_Secure_2026_Key_Must_Be_Long_Enough!";
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

// Tự động khởi tạo và seed dữ liệu nếu đang ở chế độ SQLite dev
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<SportSpotDbContext>();
    if (!isSupabaseConfigured)
    {
        db.Database.EnsureCreated();
        SeedDevVenues(db);
    }
}

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

// Hàm hỗ trợ seed sân mẫu cho môi trường dev SQLite
static void SeedDevVenues(SportSpotDbContext context)
{
    if (context.Venues.Any()) return;

    var venue1 = new Venue
    {
        SportId = 1,
        Name = "CLB Cầu Lông Cầu Giấy",
        Address = "Số 35 Trần Quý Kiên, Dịch Vọng",
        District = "Cầu Giấy",
        Latitude = 21.0368000m,
        Longitude = 105.7905000m,
        Description = "Cụm 6 sân thảm tiêu chuẩn thi đấu.",
        Hotline = "0987654321",
        BasePrice = 90000,
        PeakPrice = 120000,
        Rating = 4.9m,
        Amenities = "Bãi đỗ ô tô, Căn tin, Phòng tắm, Cho thuê vợt",
        IsActive = true
    };
    context.Venues.Add(venue1);
    context.SaveChanges();

    context.SubVenues.AddRange(
        new SubVenue { VenueId = venue1.Id, Name = "Sân Số 1 (Thảm Yonex)", IsActive = true },
        new SubVenue { VenueId = venue1.Id, Name = "Sân Số 2 (Thảm Yonex)", IsActive = true },
        new SubVenue { VenueId = venue1.Id, Name = "Sân VIP (Khán đài)", IsActive = true }
    );

    context.Services.AddRange(
        new Service { VenueId = venue1.Id, Name = "Thuê vợt Yonex Astrox", Type = "Rental", Price = 30000, StockQuantity = 20 },
        new Service { VenueId = venue1.Id, Name = "Mua ống cầu Hải Yến (12 quả)", Type = "Sale", Price = 240000, StockQuantity = 50 },
        new Service { VenueId = venue1.Id, Name = "Nước điện giải Pocari Sweat", Type = "Sale", Price = 15000, StockQuantity = 200 }
    );

    context.SaveChanges();
}
