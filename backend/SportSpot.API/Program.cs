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

// Lắng nghe trên mọi card mạng (0.0.0.0:5000) để thiết bị thật trong cùng Wi-Fi có thể kết nối
builder.WebHost.UseUrls(Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? "http://0.0.0.0:5000");

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
builder.Services.AddScoped<TeamService>();
builder.Services.AddScoped<OwnerScheduleService>();
builder.Services.AddScoped<OwnerConfigService>();
builder.Services.AddScoped<VenueApplicationService>();
builder.Services.AddScoped<AdminService>();
builder.Services.AddHttpClient<IVenueImageStorage, CloudinaryImageStorage>(client => client.Timeout = TimeSpan.FromSeconds(60));

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
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var rawId = context.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var db = context.HttpContext.RequestServices.GetRequiredService<SportSpotDbContext>();
                var user = int.TryParse(rawId, out var id) ? await db.Users.FindAsync(id) : null;
                if (user == null || !user.IsActive) { context.Fail("Tài khoản không hoạt động"); return; }
                if (context.Principal?.Identity is System.Security.Claims.ClaimsIdentity identity)
                {
                    foreach (var role in identity.FindAll(System.Security.Claims.ClaimTypes.Role).ToList()) identity.RemoveClaim(role);
                    identity.AddClaim(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, user.Role));
                }
            }
        };
    });

builder.Services.AddAuthorization();

// 5. Cấu hình CORS để ứng dụng di động Flutter có thể gọi API thuận tiện
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(origin => true)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
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
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""IsActive"" boolean DEFAULT TRUE;
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""StaffVenueId"" integer;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ApprovalStatus"" character varying(50) DEFAULT 'Approved';
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""OwnerUserId"" integer;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""RejectionReason"" character varying(1000);
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""SubmittedAt"" timestamp with time zone;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewedAt"" timestamp with time zone;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewedByUserId"" integer;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewRevision"" integer DEFAULT 0;
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""DateOfBirth"" date;
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""AvatarUrl"" character varying(255);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""FavoriteSports"" character varying(255);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""FcmToken"" character varying(500);
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""IsFindMatchEnabled"" boolean DEFAULT FALSE;
                    ALTER TABLE ""Users"" ADD COLUMN IF NOT EXISTS ""IsActive"" boolean NOT NULL DEFAULT TRUE;

                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""OwnerUserId"" integer REFERENCES ""Users""(""Id"") ON DELETE RESTRICT;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ApprovalStatus"" character varying(20) NOT NULL DEFAULT 'Approved';
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""RejectionReason"" character varying(1000);
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""SubmittedAt"" timestamp with time zone;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewedAt"" timestamp with time zone;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewedByUserId"" integer;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""ReviewRevision"" integer NOT NULL DEFAULT 0;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""MaxSlotsPerBooking"" integer NOT NULL DEFAULT 3;
                    ALTER TABLE ""Venues"" ADD COLUMN IF NOT EXISTS ""MinDepositPercent"" integer NOT NULL DEFAULT 30;
                    ALTER TABLE ""Venues"" ALTER COLUMN ""ImageUrl"" TYPE character varying(1000);

                    CREATE TABLE IF NOT EXISTS ""VenueImages"" (
                        ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                        ""UploadedByUserId"" integer NOT NULL REFERENCES ""Users""(""Id"") ON DELETE RESTRICT,
                        ""VenueId"" integer NULL REFERENCES ""Venues""(""Id"") ON DELETE SET NULL,
                        ""Url"" character varying(1000) NOT NULL,
                        ""PublicId"" character varying(255) NOT NULL,
                        ""Position"" integer NOT NULL DEFAULT 0,
                        ""CreatedAt"" timestamp with time zone NOT NULL
                    );
                    CREATE INDEX IF NOT EXISTS ""IX_VenueImages_UploadedByUserId"" ON ""VenueImages""(""UploadedByUserId"");
                    CREATE INDEX IF NOT EXISTS ""IX_VenueImages_VenueId"" ON ""VenueImages""(""VenueId"");

                    CREATE TABLE IF NOT EXISTS ""VenueModerationLogs"" (
                        ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                        ""VenueId"" integer NOT NULL REFERENCES ""Venues""(""Id"") ON DELETE CASCADE,
                        ""AdminUserId"" integer NOT NULL REFERENCES ""Users""(""Id"") ON DELETE RESTRICT,
                        ""Decision"" character varying(20) NOT NULL,
                        ""Reason"" character varying(1000) NOT NULL,
                        ""CreatedAt"" timestamp with time zone NOT NULL
                    );
                    CREATE INDEX IF NOT EXISTS ""IX_VenueModerationLogs_VenueId"" ON ""VenueModerationLogs""(""VenueId"");
                    CREATE INDEX IF NOT EXISTS ""IX_VenueModerationLogs_AdminUserId"" ON ""VenueModerationLogs""(""AdminUserId"");

                    CREATE TABLE IF NOT EXISTS ""VenueSlotConfigs"" (
                        ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                        ""VenueId"" integer NOT NULL REFERENCES ""Venues""(""Id"") ON DELETE CASCADE,
                        ""SlotId"" integer NOT NULL REFERENCES ""TimeSlots""(""Id"") ON DELETE CASCADE,
                        ""IsActive"" boolean NOT NULL DEFAULT TRUE,
                        ""IsPeak"" boolean NOT NULL DEFAULT FALSE,
                        ""CustomPrice"" integer NULL
                    );
                    CREATE UNIQUE INDEX IF NOT EXISTS ""IX_VenueSlotConfigs_VenueId_SlotId"" ON ""VenueSlotConfigs""(""VenueId"", ""SlotId"");
                    CREATE INDEX IF NOT EXISTS ""IX_VenueSlotConfigs_SlotId"" ON ""VenueSlotConfigs""(""SlotId"");

                    INSERT INTO ""TimeSlots"" (""Id"", ""StartTime"", ""EndTime"", ""IsPeak"") VALUES
                        (14, '05:00', '06:00', false),
                        (15, '11:00', '12:00', false),
                        (16, '12:00', '13:00', false),
                        (17, '13:00', '14:00', false),
                        (18, '22:00', '23:00', true),
                        (19, '23:00', '23:59', true)
                    ON CONFLICT (""Id"") DO NOTHING;
                ");
            }
            catch (Exception alterEx)
            {
                logger.LogWarning(">>> [Database] Schema safeguard: {Msg}", alterEx.Message);
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
        logger.LogError(ex, ">>> [Database] Gặp lỗi khi chạy Migration: {Message}", ex.Message);
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

app.UseRouting();
app.UseCors("AllowAll");

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
