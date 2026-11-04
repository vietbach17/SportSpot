# 📊 BÁO CÁO TỔNG QUAN TÌNH TRẠNG CÁC MODULE (SYSTEM HEALTH & MODULE STATUS)

**Dự án:** SportSpot – Multi-Sport Venue Booking & Match-Finding Platform  
**Khóa học:** PRM393 - Mobile Programming (Fall 2026)  
**Nhánh Git:** `feature/payment-tickets` & `main`  
**Ngày cập nhật:** 31/10/2026  

---

## 🌟 1. BẢNG TỔNG QUAN TIẾN ĐỘ 5 MODULES

| Module | Phân Hệ | Backend (.NET 8) | Frontend (Flutter) | Kiểm Thử Tự Động | Đánh Giá Chung |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **Module 1** | Xác thực SĐT/OTP, Guest Mode & Hồ Sơ Cá Nhân | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟢 Ổn định 100% |
| **Module 2** | Khám Phá Sân, Bộ Lọc GPS/Môn & Chi Tiết Sân Bãi | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟢 Ổn định 100% |
| **Module 3** | Lưới Khung Giờ, Giữ Chỗ 5 Phút & Chi Tiết Đơn Đặt Sân | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟢 Ổn định 100% (Đã bổ sung `BookingDetailScreen` minh bạch hóa đơn) |
| **Module 4** | Tìm Kèo Ghép, Khách Vãng Lai & Quầy Lễ Tân | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass (44/44) | 🟢 Ổn định 100% (Đã tiếp thu: Khách vãng lai tham gia không cần tạo tài khoản) |
| **Module 5** | Thanh Toán Escrow, Vé QR Offline SHA-256 & Quản Trị Ví | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass (19/19 + 26/26 FE) | 🟢 Ổn định 100% (Bổ sung Lịch sử Escrow, Rút tiền NH, Hủy vé 3 bậc, Chia sẻ vé) |

---

## 🔍 2. CHI TIẾT TỪNG MODULE

### 🔹 Module 1: Xác Thực, Phân Quyền & Hồ Sơ (Gói 1)
- **Backend**:
  - `AuthController.cs` (`/api/auth/send-otp`, `/api/auth/verify-otp`, `/api/auth/login`).
  - `UsersController.cs` (`/api/users/me`, `/api/users/profile`).
  - Cấp phát JWT Access Token và cơ chế `DevBypassAuthMiddleware` (hỗ trợ header `X-Mock-User-Id`).
- **Frontend**:
  - `onboarding_screen.dart`: Giới thiệu 3 slide hiện đại, nút "Khám phá ngay (Guest Mode)".
  - `phone_input_screen.dart` & `otp_verification_screen.dart`: Nhập SĐT, đếm ngược gửi lại OTP, tự động chuyển focus.
  - `profile_screen.dart`: Xem hồ sơ, chỉnh sửa môn thể thao yêu thích, công tắc bật/tắt "Chế độ tìm kèo".
- **Tình trạng**: **Rất ổn định**, luồng đăng nhập và quản lý token hoạt động trơn tru.

---

### 🔹 Module 2: Khám Phá Địa Điểm & Sân Thể Thao
- **Backend**:
  - `SportsController.cs` (`/api/sports`).
  - `VenuesController.cs` (`/api/venues`, `/api/venues/{id}`).
  - Tính toán khoảng cách tọa độ GPS bằng công thức toán học Haversine (`HaversineHelper.cs`).
- **Frontend**:
  - `home_screen.dart`: Thanh tìm kiếm thông minh, chips lọc 4 môn thể thao (Cầu lông, Bóng đá, Pickleball, Tennis), slider lọc bán kính GPS (1km - 20km).
  - `venue_detail_screen.dart`: Xem hình ảnh sân, danh sách sân con, tiện ích (Wifi, tắm nóng lạnh, gửi xe), nút gọi hotline và nút mở bản đồ Google Maps.
  - Hỗ trợ Mock Fallback (`venue_repository.dart` + `sportspot_mock_data.dart`) giúp app hiển thị mượt mà kể cả khi server chưa có data thật.
- **Tình trạng**: **Rất ổn định**, giao diện đẹp, đã có test tự động `module2_test.dart` (PASS).

---

### 🔹 Module 3: Lưới Khung Giờ, Giữ Chỗ & Chi Tiết Đơn Đặt Sân (Gói 2)
- **Backend**:
  - `CourtsController.cs` (`/api/courts/{subVenueId}/slots?date=...`).
  - `BookingsController.cs` (`POST /api/bookings`).
  - Cơ chế kiểm tra tối đa 3 ca liên tiếp (`CheckConsecutiveSlots`) và khóa chống trùng lịch Concurrency Lock (trả về mã HTTP 409 Conflict nếu có người khác vừa đặt).
- **Frontend**:
  - `court_slots_screen.dart`: Lưới khung giờ trực quan với 3 trạng thái (Trống, Đang giữ chỗ, Đã đặt), thanh chọn ngày cuộn ngang.
  - `booking_checkout_screen.dart`: Đồng hồ đếm ngược giữ chỗ 5 phút (`Hold Timer`), chọn phụ kiện/dịch vụ đi kèm (nước uống, thuê vợt), chọn tỷ lệ cọc 30% hoặc 100%.
  - `booking_detail_screen.dart` (**Hoàn tất theo góp ý của Thầy**): Hiển thị chi tiết bảng kê hóa đơn: tiền sân, phụ phí từng dịch vụ, tiền cọc đã giữ, tiền còn lại tại quầy lễ tân, mã QR check-in và nút hủy cọc / chia sẻ vé.
- **Tình trạng**: **100% Hoàn Thành & Sẵn Sàng**.

---

### 🔹 Module 4: Tìm Kèo Ghép Đội & Khách Vãng Lai (Gói 3)
- **Backend**:
  - `MatchesController.cs` (`/api/matches`, `POST /api/matches/{id}/join`, `POST /api/matches/{id}/guest-join`, `POST /api/matches/{id}/assign-walk-in`, `POST /api/matches/{id}/leave`).
  - Thuật toán tự động chia đều tiền sân theo đầu người (`courtPrice / neededPlayers`) với quy tắc làm tròn chuẩn xác.
  - Hỗ trợ bàn lễ tân gán người vãng lai thanh toán tiền mặt và tự động đóng kèo khi đủ người.
  - **44/44 bài test backend tự động đạt PASS 100%**.
- **Frontend**:
  - `match_feed_screen.dart`: Bảng tin kèo thể thao, bộ lọc theo môn và quận huyện, thanh tiến độ tuyển người.
  - `guest_quick_join_dialog` (**Hoàn tất theo góp ý của Thầy**): Khách vãng lai bấm tham gia không bị ép tạo tài khoản thành viên, chỉ cần điền Tên + SĐT, chọn trừ Ví tạm trên máy hoặc mock gateway và nhận vé ngay.
- **Tình trạng**: **100% Hoàn Thành & Sẵn Sàng**.

---

### 🔹 Module 5: Thanh Toán Escrow, Vé QR Offline SHA-256 & Quản Trị Ví (Gói 4 - Huy)
- **Backend**:
  - `PaymentsController.cs` (`/api/payments/create-intent`, `/api/payments/webhook-ipn`, `/api/payments/mock-pay`, `/api/payments/history`).
  - `TicketsController.cs` (`/api/tickets/my-tickets`, `/api/tickets/verify-qr`, `/api/tickets/{id}/cancel`).
  - **Cơ chế Escrow**: Tiền cọc giữ ở trạng thái `Holding`, chỉ giải ngân `Settled` cho chủ sân khi quét QR check-in hợp lệ.
  - **Chữ ký SHA-256 Checksum**: Chống làm giả vé và chống quét lại lần 2 (Replay Attack).
  - **Chính sách phạt bậc thang**: $\ge 4h$ hoàn 100%, $2h - 4h$ hoàn 50%, $< 2h$ phạt 100%. Tiền hoàn được cộng tự động vào ví.
  - **19/19 bài test backend tự động đạt PASS 100%**.
- **Frontend**:
  - `my_tickets_screen.dart`: Quản lý vé điện tử, thanh điều khiển chế độ Offline SQLite, hiển thị Ví hoàn tiền & Escrow tạm giữ.
  - `escrow_wallet_sheet.dart` (**Mở rộng nâng cao**): Bảng xem chi tiết lịch sử ký quỹ Escrow và biến động số dư ví minh bạch chuẩn Fintech.
  - `bank_withdrawal_dialog.dart` (**Mở rộng nâng cao - Theo góp ý của Thầy**): Hộp thoại rút tiền hoàn cọc về tài khoản ngân hàng thật (Vietcombank, MB, Techcombank, ACB...).
  - `cancel_ticket_dialog.dart`: Tính toán thời gian thực phần trăm hoàn phạt cọc 3 bậc và hoàn tiền vào ví tức thì.
  - `ticket_share_helper.dart` (**Mở rộng nâng cao**): Tiện ích sao chép và chia sẻ vé vào sân cho đồng đội qua Zalo/Messenger.
  - `qr_scanner_screen.dart`: Quầy lễ tân quét QR giả lập giải ngân tiền Escrow (`Holding` $\to$ `Settled`).
- **Tình trạng**: **Hoàn chỉnh và mở rộng chuyên sâu 100%**.

---

## 🎯 3. TỔNG KẾT & ĐÁNH GIÁ MỨC ĐỘ SẴN SÀNG

1. **Về mặt kỹ thuật**: 
   - Backend .NET 8: **63/63 Tests PASS** (44 Module 4 + 19 Module 5).
   - Frontend Flutter: **26/26 Tests PASS** trên toàn bộ 7 test files.
   - Dart Static Analysis: **0 Errors**, mã nguồn sạch đẹp chuẩn clean code.
2. **Về mặt demo cho Giảng viên**: Nhóm đã có thể demo mượt mà trọn vẹn luồng từ:
   - Onboarding $	o$ Khám phá sân $	o$ Đặt giờ thi đấu $	o$ Giữ chỗ 5 phút $	o$ Thanh toán cọc Escrow $	o$ Hóa đơn chi tiết $	o$ Sinh vé QR Offline SQLite $	o$ Khách vãng lai tham gia $	o$ Quét QR giải ngân tại sân $	o$ Rút tiền về ngân hàng.
