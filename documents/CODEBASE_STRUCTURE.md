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
├── SportSpot.sln              # File Solution liên kết các projects của Backend
│
├── SportSpot.API/             # 🖥️ [TẦNG 1 - PRESENTATION LAYER]: Tiếp nhận HTTP Request & trả về JSON
│   ├── Controllers/           # Các API Controller mỏng (chỉ gọi xuống tầng Services, không viết logic DB tại đây):
│   │   ├── AuthController.cs       # [Module 1] Gửi mã OTP, xác thực OTP, đăng nhập cấp phát JWT Token
│   │   ├── UsersController.cs      # [Module 1] Xem thông tin cá nhân (/me), cập nhật hồ sơ & bật chế độ tìm kèo
│   │   ├── SportsController.cs     # [Module 2] Lấy danh sách bộ môn thể thao
│   │   ├── VenuesController.cs     # [Module 2] Tìm kiếm sân theo từ khóa/GPS, xem chi tiết sân
│   │   ├── CourtsController.cs     # [Module 3] Lấy danh sách khung giờ (slots) của sân con theo ngày
│   │   ├── BookingsController.cs   # [Module 3] Đặt sân, kiểm tra chọn tối đa 3 slot liên tiếp & chống trùng lịch (409)
│   │   ├── MatchesController.cs    # [Module 4] Bảng tin kèo mở, tham gia kèo, lễ tân gán khách lẻ tại quầy
│   │   ├── PaymentsController.cs   # [Module 5] Khởi tạo giao dịch thanh toán cọc Escrow, xử lý Webhook & Mock Pay
│   │   └── TicketsController.cs    # [Module 5] Lấy danh sách vé QR, quét QR check-in giải ngân, hủy vé phạt bậc thang
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
├── SportSpot.Data/            # 🗄️ [TẦNG 3 - DATA ACCESS LAYER]: Tương tác và truy vấn Cơ sở dữ liệu
│   ├── Context/
│   │   ├── SportSpotDbContext.cs        # Cấu hình EF Core DbContext, bảng, khóa ngoại và ràng buộc chống trùng lịch
│   │   └── SportSpotDbContextFactory.cs # Design-time Factory sinh EF Core Migrations cho PostgreSQL (Npgsql)
│   ├── Migrations/            # Bộ file EF Core Migrations tự động khởi tạo bảng trên PostgreSQL
│   ├── Entities/              # 12 class đại diện cho 12 bảng trong Database:
│   │   └── Sport.cs, User.cs, Venue.cs, SubVenue.cs, Service.cs, TimeSlot.cs,
│   │       Booking.cs, BookingDetail.cs, BookingService.cs, OpenMatch.cs, MatchMember.cs, Transaction.cs
│   ├── Repositories/          # Tầng trung gian thực hiện các truy vấn dữ liệu (Repository & UnitOfWork Pattern):
│   │   ├── Interfaces/
│   │   │   ├── IGenericRepository.cs   # Các thao tác đọc/ghi cơ bản dùng chung (GetById, GetAll, Add, Update, Remove)
│   │   │   ├── IUnitOfWork.cs          # Gom nhóm toàn bộ Repositories và quản lý lưu thay đổi (SaveChangesAsync)
│   │   │   └── IUserRepository.cs, ISportRepository.cs, IVenueRepository.cs,
│   │   │       IBookingRepository.cs, IMatchRepository.cs, ITransactionRepository.cs
│   │   └── Implementations/   # Cài đặt chi tiết các câu truy vấn EF Core (Include, Where, OrderBy) cho từng bảng
│   └── SeedData/
│       └── DbInitializer.cs   # Tự động nạp dữ liệu sân mẫu phong phú khi khởi chạy môi trường dev
│
├── SportSpot.Module4.Tests/   # 🧪 [TESTS]: Bộ 44 bài test tự động cho Kèo Đấu & Ghép Vãng Lai
└── SportSpot.Module5.Tests/   # 🧪 [TESTS]: Bộ 19 bài test tự động cho Thanh Toán Escrow, QR SHA-256 & Hủy Vé
```

---

## 3. Cấu Trúc Thư Mục `frontend/` (Ứng Dụng Flutter Đa Nền Tảng)

Thư mục `frontend/` chứa mã nguồn ứng dụng Flutter hoàn chỉnh của cả 5 phân hệ:

```text
frontend/
├── pubspec.yaml               # Thư viện: provider, http, shared_preferences, sqflite, qr_flutter, google_fonts...
└── lib/
    ├── core/                  # 🛠️ Các thành phần cốt lõi dùng chung toàn ứng dụng
    │   ├── constants/
    │   │   └── api_constants.dart      # Cấu hình Base URL API (localhost:5000 / 10.0.2.2:5000) & các đường dẫn Endpoint
    │   ├── network/
    │   │   └── api_client.dart         # Singleton HTTP Client tự động đính kèm JWT Token và giải mã JSON UTF-8
    │   └── theme/
    │       └── app_theme.dart          # Cấu hình bảng màu chuẩn, typography và giao diện Material 3
    │
    ├── data/                  # 💾 Tầng dữ liệu (Models, Repositories & Local Storage)
    │   ├── models/
    │   │   ├── user_model.dart         # [Module 1] Model người dùng & profile
    │   │   ├── venue_model.dart        # [Module 2] Model sân thể thao, tiện ích, môn đấu
    │   │   ├── booking_model.dart      # [Module 3] Model đặt chỗ, khung giờ, chi phí
    │   │   ├── match_model.dart        # [Module 4] Model kèo ghép vãng lai
    │   │   └── ticket_model.dart       # [Module 5] Model vé QR, hóa đơn Escrow, kết quả hoàn tiền
    │   ├── repositories/
    │   │   ├── venue_repository.dart   # [Module 2] Repository tìm kiếm sân (kèm mock fallback)
    │   │   ├── booking_repository.dart # [Module 3] Repository đặt sân & slot
    │   │   ├── match_repository.dart   # [Module 4] Repository ghép kèo
    │   │   ├── ticket_repository.dart  # [Module 5] Repository vé điện tử (đồng bộ SQLite offline)
    │   │   └── mock_ticket_repository.dart # [Module 5] Mock repository SHA-256 thuần Dart
    │   └── services/
    │       ├── database_helper.dart    # Khởi tạo bảng SQLite offline_bookings, user_session, app_settings
    │       └── token_service.dart      # Quản lý lưu trữ JWT Access Token trong SharedPreferences
    │
    ├── providers/             # 🔄 Tầng quản lý trạng thái (State Management - Provider)
    │   ├── auth_provider.dart          # [Module 1] Trạng thái đăng nhập, Guest Mode, OTP & Profile
    │   ├── venue_provider.dart         # [Module 2] Danh sách sân, bộ lọc bán kính GPS & môn thể thao
    │   ├── booking_provider.dart       # [Module 3] Lựa chọn slot, đếm ngược giữ chỗ 5 phút & giỏ hàng
    │   └── ticket_provider.dart        # [Module 5] Danh sách vé, số dư Ví, Escrow Holding & công tắc Offline SQLite
    │
    ├── screens/               # 📱 Các màn hình giao diện theo từng phân hệ
    │   ├── onboarding/
    │   │   └── onboarding_screen.dart  # [Module 1] Màn hình chào mừng & giới thiệu app
    │   ├── auth/
    │   │   ├── phone_input_screen.dart # [Module 1] Nhập số điện thoại gửi OTP
    │   │   └── otp_verification_screen.dart # [Module 1] Xác thực mã OTP 6 số
    │   ├── profile/
    │   │   └── profile_screen.dart     # [Module 1] Hồ sơ cá nhân & bật/tắt tìm kèo
    │   ├── home/
    │   │   └── home_screen.dart        # [Module 2] Trang chủ khám phá sân & bộ lọc thể thao
    │   ├── venues/
    │   │   └── venue_detail_screen.dart# [Module 2] Chi tiết sân bãi, tiện ích, hotline & bản đồ
    │   ├── booking/
    │   │   ├── court_slots_screen.dart # [Module 3] Lưới chọn khung giờ trực quan (chọn tối đa 3 ca)
    │   │   └── booking_checkout_screen.dart # [Module 3] Xác nhận đơn & đồng hồ giữ chỗ 5 phút
    │   ├── matches/
    │   │   ├── match_feed_screen.dart  # [Module 4] Bảng tin tìm kèo & xem chi tiết kèo
    │   │   └── match_checkout_screen.dart # [Module 4] Tạo kèo tuyển người ghép sân
    │   ├── payment/
    │   │   └── payment_checkout_screen.dart # [Module 5] Thanh toán cọc Escrow (VNPay, MoMo, Ví, ATM)
    │   ├── tickets/
    │   │   ├── my_tickets_screen.dart  # [Module 5] Tab 3: Vé của tôi & quản lý ví hoàn tiền
    │   │   ├── ticket_qr_detail_screen.dart # [Module 5] Chi tiết vé QR (chữ ký SHA-256, chạy Offline)
    │   │   ├── qr_scanner_screen.dart  # [Module 5] Quầy lễ tân quét QR giải ngân Escrow
    │   │   └── cancel_ticket_dialog.dart # [Module 5] Hộp thoại hủy vé phạt bậc thang (100%/50%/0%)
    │   └── main/
    │       └── main_screen.dart        # Khung điều hướng 4 Tab (Trang chủ, Tìm kèo, Vé của tôi, Cá nhân)
    │
    └── widgets/               # 🧩 Các UI components tái sử dụng
        ├── match_ui.dart               # Theme và thẻ hiển thị kèo đấu thể thao
        ├── recruitment_form.dart       # Form nhập số người tuyển & tính tiền chia theo đầu người
        ├── date_selector_widget.dart   # Thanh cuộn chọn ngày thi đấu
        ├── time_slot_grid_widget.dart  # Lưới hiển thị trạng thái từng slot giờ
        ├── floating_bottom_bar.dart    # Thanh điều hướng nổi hiện đại
        └── responsive_phone_frame.dart # Khung giả lập giao diện mobile khi chạy trên Web
```
