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
var rawConn = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
              ?? builder.Configuration.GetConnectionString("DefaultConnection");

var connectionString = ConvertPostgresUriToConnectionString(rawConn ?? string.Empty);

var isPostgresConfigured = !string.IsNullOrWhiteSpace(connectionString) && 
                           !connectionString.Contains("your-project") &&
                           (connectionString.Contains("Host=") || connectionString.Contains("Server="));

builder.Services.AddDbContext<SportSpotDbContext>(options =>
{
    if (isPostgresConfigured)
    {
        options.UseNpgsql(connectionString);
    }
    else
    {
        // Chế độ Dev/Test cục bộ không cần mạng hay PostgreSQL bên ngoài
        options.UseSqlite("Data Source=sportspot_dev.db");
    }
});

// 2. Cấu hình MemoryCache cho OTP
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
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 6. Controllers & JSON Enum
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

// 7. Swagger / OpenAPI Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SportSpot API - Nền tảng đặt sân thể thao & Tìm kèo giao lưu",
        Version = "v1",
        Description = "Tài liệu API dành cho ứng dụng Flutter và Web Admin (Môn PRM393)."
    });

    // Thêm cấu hình nhập Bearer Token trên Swagger UI
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token JWT theo định dạng: Bearer {token}",
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

// Tự động khởi tạo database (Migration) và seed dữ liệu mẫu
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<SportSpotDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        if (isPostgresConfigured)
        {
            logger.LogInformation("==================================================");
            logger.LogInformation(">>> [Database] Đang kết nối PostgreSQL & tự động chạy Migration...");
            db.Database.Migrate();
            logger.LogInformation(">>> [Database] Khởi tạo schema PostgreSQL thành công!");
            logger.LogInformation("==================================================");
        }
        else
        {
            logger.LogInformation(">>> [Database] Đang sử dụng SQLite local dev (sportspot_dev.db)...");
            db.Database.EnsureCreated();
        }

        SeedDevVenues(db);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, ">>> [Database] Gặp lỗi khi chạy Migration: {Message}", ex.Message);
        if (isPostgresConfigured)
        {
            try
            {
                logger.LogWarning(">>> [Database] Thử fallback với EnsureCreated()...");
                db.Database.EnsureCreated();
                SeedDevVenues(db);
            }
            catch (Exception fallbackEx)
            {
                logger.LogError(fallbackEx, ">>> [Database] Fallback EnsureCreated cũng thất bại: {Message}", fallbackEx.Message);
            }
        }
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

// Chuyển đổi định dạng URI postgresql://... sang ADO.NET connection string nếu cần
static string ConvertPostgresUriToConnectionString(string raw)
{
    if (string.IsNullOrWhiteSpace(raw)) return raw;
    raw = raw.Trim();
    if (raw.StartsWith("postgres://") || raw.StartsWith("postgresql://"))
    {
        try
        {
            var uri = new Uri(raw);
            var userInfo = uri.UserInfo.Split(':');
            var user = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : "";
            var pass = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : "";
            var host = uri.Host;
            var port = uri.Port > 0 ? uri.Port : 5432;
            var db = uri.AbsolutePath.TrimStart('/');
            return $"Host={host};Port={port};Database={db};Username={user};Password={pass};SSL Mode=Prefer;Trust Server Certificate=true;";
        }
        catch
        {
            return raw;
        }
    }
    return raw;
}

// Hàm hỗ trợ seed sân mẫu và dữ liệu dev cho môi trường dev
static void SeedDevVenues(SportSpotDbContext context)
{
    // 1. Seed User mẫu nếu chưa có
    if (!context.Users.Any())
    {
        var testUser = new User
        {
            Id = 1,
            FullName = "Nguyễn Văn Test",
            PhoneNumber = "0901234567",
            Email = "test@sportspot.vn",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
            Role = "Player",
            WalletBalance = 500000,
            IsFindMatchEnabled = true,
            CreatedAt = DateTime.UtcNow
        };
        context.Users.Add(testUser);
        context.SaveChanges();
    }

    // 2. Seed Venues nếu chưa có
    if (!context.Venues.Any())
    {
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
            ImageUrl = "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800",
            IsActive = true
        };

        var venue2 = new Venue
        {
            SportId = 2,
            Name = "Sân Bóng Đá Mini PVV",
            Address = "Số 72 Trần Thái Tông, Dịch Vọng Hậu",
            District = "Cầu Giấy",
            Latitude = 21.0305000m,
            Longitude = 105.7865000m,
            Description = "Cụm sân cỏ nhân tạo 7 người chất lượng cao.",
            Hotline = "0912345678",
            BasePrice = 350000,
            PeakPrice = 600000,
            Rating = 4.7m,
            Amenities = "Đèn chiếu sáng ban đêm, Trọng tài, Căn tin, Giữ xe miễn phí",
            ImageUrl = "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
            IsActive = true
        };

        context.Venues.AddRange(venue1, venue2);
        context.SaveChanges();
    }

    var v1 = context.Venues.FirstOrDefault(v => v.SportId == 1) ?? context.Venues.FirstOrDefault();
    var v2 = context.Venues.FirstOrDefault(v => v.SportId == 2) ?? context.Venues.LastOrDefault();

    // 3. Seed SubVenues nếu chưa có
    if (!context.SubVenues.Any() && v1 != null)
    {
        var subVenues = new List<SubVenue>
        {
            new() { VenueId = v1.Id, Name = "Sân Thảm 1", IsActive = true },
            new() { VenueId = v1.Id, Name = "Sân Thảm 2", IsActive = true },
            new() { VenueId = v1.Id, Name = "Sân Thảm 3", IsActive = true },
        };
        if (v2 != null && v2.Id != v1.Id)
        {
            subVenues.Add(new() { VenueId = v2.Id, Name = "Sân Cỏ 7A", IsActive = true });
            subVenues.Add(new() { VenueId = v2.Id, Name = "Sân Cỏ 7B", IsActive = true });
        }
        context.SubVenues.AddRange(subVenues);
        context.SaveChanges();
    }

    // 4. Seed Services nếu chưa có
    if (!context.Services.Any() && v1 != null)
    {
        var services = new List<Service>
        {
            new() { VenueId = v1.Id, Name = "Nước suối Aquafina 500ml", Type = "Sale", Price = 10000, StockQuantity = 100 },
            new() { VenueId = v1.Id, Name = "Thuê vợt Yonex chính hãng", Type = "Rental", Price = 30000, StockQuantity = 20 },
            new() { VenueId = v1.Id, Name = "Ống cầu lông Hải Yến (12 quả)", Type = "Sale", Price = 60000, StockQuantity = 50 },
        };
        if (v2 != null && v2.Id != v1.Id)
        {
            services.Add(new() { VenueId = v2.Id, Name = "Nước khoáng bù điện giải Revive", Type = "Sale", Price = 15000, StockQuantity = 100 });
            services.Add(new() { VenueId = v2.Id, Name = "Thuê bộ áo pitch tập luyện (10 áo)", Type = "Rental", Price = 40000, StockQuantity = 10 });
            services.Add(new() { VenueId = v2.Id, Name = "Thuê bóng thi đấu Động Lực số 5", Type = "Rental", Price = 30000, StockQuantity = 15 });
        }
        context.Services.AddRange(services);
        context.SaveChanges();
    }
}
