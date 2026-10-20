# 🗂️ Cấu Trúc Mã Nguồn Dự Án (Codebase Structure Guide)

Tài liệu này giải thích khái quát tổ chức thư mục và nhiệm vụ của từng file trong dự án **SportSpot**, giúp cả 5 thành viên nắm bắt nhanh cấu trúc dự án và làm việc song song mà không bị xung đột mã nguồn (Merge Conflict).

---

## 1. Tổng Quan Thư Mục Gốc (`SportSpot/`)

```text
SportSpot/
├── documents/                 # 📚 Bộ tài liệu đặc tả PRD 2.0, hướng dẫn chia task & cấu trúc code
├── backend/                   # 🖥️ Hệ thống Backend RESTful API (.NET 8 - Kiến trúc 3 Layers + Repository)
├── frontend/                  # 📱 Ứng dụng đa nền tảng Flutter 3.x (Android, iOS, Web, Desktop)
├── dev.bat                    # ⚡ Trình điều khiển khởi động nhanh cả Backend (Port 5000) & Frontend (Port 3000)
├── AGENT.md                   # 🤖 Quy tắc hoạt động bắt buộc cho AI Assistant khi hỗ trợ dự án
├── .gitignore                 # Loại trừ các thư mục biên dịch tạm (bin/, obj/, build/, .dart_tool/, *.db, .env)
└── README.md                  # Trang giới thiệu ngắn gọn dự án & hướng dẫn khởi chạy nhanh
```

---

## 2. Cấu Trúc Thư Mục `backend/` (.NET 8 – Kiến Trúc 3 Layers + Repository)

Backend được tách thành **3 Projects độc lập** bên trong Solution `SportSpot.sln`.  
**Luồng xử lý chuẩn:** `Controller (API)` $\longrightarrow$ `Service (BLL)` $\longrightarrow$ `UnitOfWork / Repository (DAL)` $\longrightarrow$ `Database`.

```text
backend/
├── SportSpot.sln              # File Solution liên kết 3 projects của Backend
│
├── SportSpot.API/             # 🖥️ [TẦNG 1 - PRESENTATION LAYER]: Tiếp nhận HTTP Request & trả về JSON
│   ├── Controllers/           # Các API Controller mỏng (chỉ gọi xuống tầng Services, không viết logic DB tại đây):
│   │   ├── AuthController.cs       # [TV1] Gửi mã OTP, xác thực OTP, đăng nhập cấp phát JWT Token
│   │   ├── UsersController.cs      # [TV1] Xem thông tin cá nhân (/me), cập nhật hồ sơ & bật chế độ tìm kèo
│   │   ├── SportsController.cs     # [TV2] Lấy danh sách 4 bộ môn thể thao kèm số lượng sân đang mở
│   │   ├── VenuesController.cs     # [TV2] Tìm kiếm sân theo từ khóa/bán kính GPS, xem chi tiết sân & khung giờ
│   │   ├── BookingsController.cs   # [TV3] Đặt sân, kiểm tra chọn tối đa 3 slot liên tiếp & chống trùng lịch (409)
│   │   ├── MatchesController.cs    # [TV4] Lấy danh sách kèo mở, tham gia kèo, lễ tân gán khách lẻ tại quầy
│   │   ├── PaymentsController.cs   # [TV5] Khởi tạo giao dịch thanh toán cọc Escrow, xử lý Webhook & Mock Pay
│   │   └── TicketsController.cs    # [TV5] Lấy danh sách vé QR, quét QR check-in giải ngân, hủy vé phạt bậc thang
│   ├── Middlewares/
│   │   └── DevBypassAuthMiddleware.cs # Cho phép gửi kèm header "X-Mock-User-Id" để test API nhanh không cần login
│   ├── .env.example           # Mẫu cấu hình biến môi trường (DATABASE_CONNECTION_STRING, JWT_SECRET_KEY)
│   ├── appsettings.json       # Cấu hình mặc định của server
│   └── Program.cs             # Điểm khởi chạy server: nạp .env, cấu hình DB/Auto-Migrate, đăng ký DI, CORS, Swagger
│
├── SportSpot.Services/        # ⚙️ [TẦNG 2 - BUSINESS LOGIC LAYER]: Chứa toàn bộ quy tắc nghiệp vụ
│   ├── DTOs/                  # Khuôn mẫu dữ liệu đầu vào (Request) và đầu ra (Response) cho từng phân hệ:
│   │   ├── ApiResponse.cs          # Khung JSON trả về thống nhất (Success, StatusCode, Message, Data)
│   │   ├── AuthDto.cs              # Dữ liệu gửi/xác thực OTP và phản hồi đăng nhập
│   │   ├── UserProfileDto.cs       # Dữ liệu hồ sơ người dùng và cài đặt tìm kèo
│   │   ├── SportDto.cs             # Dữ liệu hiển thị môn thể thao
│   │   ├── VenueDto.cs             # Dữ liệu danh sách sân, chi tiết sân con, dịch vụ và trạng thái slot giờ
│   │   ├── BookingDto.cs           # Dữ liệu tạo đơn đặt sân và thông tin cuống vé trả về
│   │   ├── MatchDto.cs             # Dữ liệu bảng tin ghép kèo vãng lai và yêu cầu tham gia kèo
│   │   └── PaymentTicketDto.cs     # Dữ liệu giao dịch thanh toán Escrow và kết quả hoàn tiền hủy vé
│   ├── Helpers/               # Các hàm tính toán tiện ích dùng chung:
│   │   ├── HaversineHelper.cs      # Công thức toán học tính khoảng cách km giữa tọa độ GPS của User và Sân
│   │   └── QrChecksumHelper.cs     # Tạo và kiểm tra chữ ký băm SHA-256 chống giả mạo chuỗi mã QR
│   ├── Interfaces/            # Hợp đồng giao diện (Interface) cho các dịch vụ nghiệp vụ:
│   │   └── IAuthService.cs, IUserService.cs, ISportService.cs, IVenueService.cs,
│   │       IBookingService.cs, IMatchService.cs, IPaymentService.cs, ITicketService.cs, IJwtService.cs
│   └── Implementations/       # Cài đặt chi tiết logic nghiệp vụ tương ứng với từng Interface ở trên
│
└── SportSpot.Data/            # 🗄️ [TẦNG 3 - DATA ACCESS LAYER]: Tương tác và truy vấn Cơ sở dữ liệu
    ├── Context/
    │   ├── SportSpotDbContext.cs        # Cấu hình EF Core DbContext, bảng, khóa ngoại và ràng buộc chống trùng lịch
    │   └── SportSpotDbContextFactory.cs # Design-time Factory sinh EF Core Migrations cho PostgreSQL (Npgsql)
    ├── Migrations/            # Bộ file EF Core Migrations tự động khởi tạo bảng trên PostgreSQL
    ├── Entities/              # 12 class đại diện cho 12 bảng trong Database:
    │   └── Sport.cs, User.cs, Venue.cs, SubVenue.cs, Service.cs, TimeSlot.cs,
    │       Booking.cs, BookingDetail.cs, BookingService.cs, OpenMatch.cs, MatchMember.cs, Transaction.cs
    ├── Repositories/          # Tầng trung gian thực hiện các truy vấn dữ liệu (Repository & UnitOfWork Pattern):
    │   ├── Interfaces/
    │   │   ├── IGenericRepository.cs   # Các thao tác đọc/ghi cơ bản dùng chung (GetById, GetAll, Add, Update, Remove)
    │   │   ├── IUnitOfWork.cs          # Gom nhóm toàn bộ Repositories và quản lý lưu thay đổi (SaveChangesAsync)
    │   │   └── IUserRepository.cs, ISportRepository.cs, IVenueRepository.cs,
    │   │       IBookingRepository.cs, IMatchRepository.cs, ITransactionRepository.cs
    │   └── Implementations/   # Cài đặt chi tiết các câu truy vấn EF Core (Include, Where, OrderBy) cho từng bảng
    └── SeedData/
        └── DbInitializer.cs   # Tự động nạp dữ liệu sân mẫu (SeedDevVenues) khi khởi chạy môi trường dev
```

---

## 3. Cấu Trúc Thư Mục `frontend/` (Ứng Dụng Flutter Đa Nền Tảng)

Thư mục `frontend/` chứa mã nguồn ứng dụng Flutter (hỗ trợ cả Mobile Android/iOS và Web):

```text
frontend/
├── pubspec.yaml               # Khai báo thư viện: provider, http, shared_preferences, sqflite, path, intl
└── lib/
    ├── core/                  # 🛠️ Các thành phần cốt lõi dùng chung toàn ứng dụng
    │   ├── constants/
    │   │   └── api_constants.dart      # Cấu hình Base URL API (localhost:5000 / 10.0.2.2:5000) & các đường dẫn Endpoint
    │   ├── network/
    │   │   └── api_client.dart         # Singleton HTTP Client tự động đính kèm JWT Token và giải mã JSON UTF-8
    │   └── theme/
    │       └── app_theme.dart          # Cấu hình bảng màu và giao diện Material 3 của ứng dụng
    │
    ├── data/                  # 💾 Tầng dữ liệu (Models & Local Storage Services)
    │   ├── models/
    │   │   └── user_model.dart         # Model ánh xạ dữ liệu hồ sơ người dùng (UserModel)
    │   └── services/
    │       ├── database_helper.dart    # Khởi tạo 4 bảng SQLite (user_session, app_settings, offline_bookings, favorites) kèm Web fallback
    │       └── token_service.dart      # Quản lý lưu trữ JWT Access Token và cờ Onboarding trong SharedPreferences
    │
    ├── providers/             # 🔄 Tầng quản lý trạng thái (State Management - Provider)
    │   └── auth_provider.dart          # Quản lý trạng thái đăng nhập, Guest Mode, gửi/xác thực OTP và cập nhật Profile
    │
    ├── screens/               # 📱 Các màn hình giao diện theo từng phân hệ
    │   ├── onboarding/
    │   │   └── onboarding_screen.dart  # [Module 1] Màn hình giới thiệu ứng dụng lần đầu mở app
    │   ├── auth/
    │   │   ├── phone_input_screen.dart # [Module 1] Màn hình nhập số điện thoại yêu cầu mã OTP
    │   │   └── otp_verification_screen.dart # [Module 1] Màn hình nhập và xác thực mã OTP 6 chữ số
    │   ├── profile/
    │   │   └── profile_screen.dart     # [Module 1] Màn hình hồ sơ cá nhân & bật/tắt công tắc "Chế độ tìm kèo"
    │   └── main/
    │       └── main_screen.dart        # Khung điều hướng BottomNavigationBar 4 tab (Trang chủ, Tìm kèo, Vé của tôi, Cá nhân)
    │
    └── main.dart              # Điểm khởi chạy ứng dụng Flutter, khởi tạo MultiProvider và điều hướng ban đầu
```
