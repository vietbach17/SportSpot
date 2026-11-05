using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SportSpot.API.Middlewares;
using SportSpot.Data.Context;
using SportSpot.Data.Repositories.Implementations;
using SportSpot.Data.Repositories.Interfaces;
using SportSpot.Data.SeedData;
using SportSpot.Services.Implementations;
using SportSpot.Services.Interfaces;

// Nạp các biến môi trường từ file .env (nếu có)
DotNetEnv.Env.TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// Lắng nghe trên mọi card mạng (0.0.0.0:5129) để localhost, thiết bị thật và Emulator đều kết nối được
builder.WebHost.UseUrls(Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? "http://0.0.0.0:5129");

// 1. Cấu hình EF Core: Ưu tiên lấy từ file .env, sau đó mới đến appsettings.json
var rawConn = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
              ?? builder.Configuration.GetConnectionString("DefaultConnection");

var connectionString = ConvertPostgresUriToConnectionString(rawConn ?? string.Empty);

var forceSqlite = string.Equals(Environment.GetEnvironmentVariable("USE_SQLITE"), "true", StringComparison.OrdinalIgnoreCase);

var isPostgresConfigured = !forceSqlite &&
                           !string.IsNullOrWhiteSpace(connectionString) && 
                           !connectionString.Contains("your-project") &&
                           !connectionString.Contains("your-password") &&
                           !connectionString.Contains("sportspot_dev.db") &&
                           (connectionString.Contains("Host=") || connectionString.Contains("Server="));

if (isPostgresConfigured)
{
    try
    {
        using var testConn = new Npgsql.NpgsqlConnection(connectionString + ";Timeout=2;Command Timeout=2;");
        testConn.Open();
    }
    catch (Exception ex)
    {
        Console.WriteLine($">>> [Database Warning] Không thể kết nối PostgreSQL Cloud ({ex.Message}). Tự động fallback sang SQLite local (sportspot_dev.db)...");
        isPostgresConfigured = false;
    }
}

builder.Services.AddDbContext<SportSpotDbContext>(options =>
{
    if (isPostgresConfigured)
    {
        options.UseNpgsql(connectionString, b => b.MigrationsAssembly("SportSpot.Data"));
    }
    else
    {
        // Chế độ Dev/Test cục bộ không cần mạng hay PostgreSQL bên ngoài
        options.UseSqlite("Data Source=sportspot_dev.db");
    }
});

// 2. Cấu hình MemoryCache cho OTP
builder.Services.AddMemoryCache();

// 3. Đăng ký Dependency Injection cho Tầng Data (Repositories & UnitOfWork) và Tầng Services
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<ISportRepository, SportRepository>();
builder.Services.AddScoped<IVenueRepository, VenueRepository>();
builder.Services.AddScoped<IBookingRepository, BookingRepository>();
builder.Services.AddScoped<IMatchRepository, MatchRepository>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ISportService, SportService>();
builder.Services.AddScoped<IVenueService, VenueService>();
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<IMatchService, MatchService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<ITicketService, TicketService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IOwnerService, OwnerService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IFcmPushService, FcmPushService>();

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
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
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
            try
            {
                db.Database.ExecuteSqlRaw(@"
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""DateOfBirth"" date;
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""AvatarUrl"" character varying(255);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""FavoriteSports"" character varying(255);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""FcmToken"" character varying(500);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""IsFindMatchEnabled"" boolean DEFAULT FALSE;
                ");
            }
            catch (Exception alterEx)
            {
                logger.LogWarning(">>> [Database] Cột người dùng: {Msg}", alterEx.Message);
            }
            logger.LogInformation(">>> [Database] Khởi tạo schema PostgreSQL thành công!");
            logger.LogInformation("==================================================");
        }
        else
        {
            logger.LogInformation(">>> [Database] Đang sử dụng SQLite local dev (sportspot_dev.db)...");
            db.Database.EnsureCreated();
            SqliteModule4Upgrade.Apply(db);
        }

        DbInitializer.SeedDevVenues(db);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, ">>> [Database] Gặp lỗi khi khởi tạo database: {Message}", ex.Message);
        if (isPostgresConfigured)
        {
            try
            {
                logger.LogWarning(">>> [Database] Thử fallback với EnsureCreated()...");
                db.Database.EnsureCreated();
                DbInitializer.SeedDevVenues(db);
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

// Authentication & Authorization
app.UseAuthentication();
app.UseMiddleware<DevBypassAuthMiddleware>();
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
