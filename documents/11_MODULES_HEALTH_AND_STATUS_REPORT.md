# 📊 BÁO CÁO TỔNG QUAN TÌNH TRẠNG CÁC MODULE (SYSTEM HEALTH & MODULE STATUS)

**Dự án:** SportSpot – Multi-Sport Venue Booking & Match-Finding Platform  
**Khóa học:** PRM393 - Mobile Programming (Fall 2026)  
**Nhánh Git:** `main` (Đã đồng bộ toàn bộ commits mới nhất)  
**Ngày cập nhật:** 25/10/2026  

---

## 🌟 1. BẢNG TỔNG QUAN TIẾN ĐỘ 5 MODULES

| Module | Phân Hệ | Backend (.NET 8) | Frontend (Flutter) | Kiểm Thử Tự Động | Đánh Giá Chung |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **Module 1** | Xác thực SĐT/OTP, Guest Mode & Hồ Sơ Cá Nhân | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟢 Ổn định 100% |
| **Module 2** | Khám Phá Sân, Bộ Lọc GPS/Môn & Chi Tiết Sân Bãi | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟢 Ổn định 100% |
| **Module 3** | Lưới Khung Giờ, Giữ Chỗ 5 Phút & Khóa Trùng Lịch | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass | 🟡 Ổn định (Cần thêm UI chi tiết đơn sau khi đặt theo góp ý của Thầy) |
| **Module 4** | Tìm Kèo Ghép, Chia Tiền Đội & Người Vãng Lai | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass (44/44) | 🟡 Ổn định (Cần chỉnh luồng Guest Join không bắt tạo account theo góp ý của Thầy) |
| **Module 5** | Thanh Toán Escrow, Vé QR Offline SHA-256 & Hủy Vé | ✅ Hoàn thành | ✅ Hoàn thành | ✅ Pass (19/19) | 🟢 Ổn định 100% |

---

## 🔍 2. CHI TIẾT TỪNG MODULE

### 🔹 Module 1: Xác Thực, Phân Quyền & Hồ Sơ (Member 1)
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

### 🔹 Module 2: Khám Phá Địa Điểm & Sân Thể Thao (Member 2)
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

### 🔹 Module 3: Lưới Khung Giờ & Khóa Giữ Chỗ Chống Trùng Lịch (Member 3)
- **Backend**:
  - `CourtsController.cs` (`/api/courts/{subVenueId}/slots?date=...`).
  - `BookingsController.cs` (`POST /api/bookings`).
  - Cơ chế kiểm tra tối đa 3 ca liên tiếp (`CheckConsecutiveSlots`) và khóa chống trùng lịch Concurrency Lock (trả về mã HTTP 409 Conflict nếu có người khác vừa đặt).
- **Frontend**:
  - `court_slots_screen.dart`: Lưới khung giờ trực quan với 3 trạng thái (Trống, Đang giữ chỗ, Đã đặt), thanh chọn ngày cuộn ngang.
  - `booking_checkout_screen.dart`: Đồng hồ đếm ngược giữ chỗ 5 phút (`Hold Timer`), chọn phụ kiện/dịch vụ đi kèm (nước uống, thuê vợt), chọn tỷ lệ cọc 30% hoặc 100%.
- **Tình trạng**: **Nghiệp vụ backend & FE đã hoàn thành tốt**.
- ⚠️ **Điểm cần lưu ý (Góp ý của Thầy)**: Hiện tại sau khi bấm xác nhận đặt sân, app chỉ hiện 1 popup nhỏ rồi bắt người dùng "Về Trang Chủ". Còn thiếu **Màn hình UI xem Chi Tiết Đơn Đặt Sân** (`BookingDetailScreen`) để người dùng xem lại bảng kê chi phí sân, chi phí dịch vụ/phụ kiện, tiền cọc và tiền còn lại cần trả tại quầy.

---

### 🔹 Module 4: Tìm Kèo Ghép Đội & Người Chơi Vãng Lai (Member 4)
- **Backend**:
  - `MatchesController.cs` (`/api/matches`, `/api/matches/{id}/join`, `/api/matches/{id}/assign-walk-in`, `/api/matches/{id}/leave`).
  - Thuật toán tự động chia đều tiền sân theo đầu người (`courtPrice / neededPlayers`) với quy tắc làm tròn chuẩn xác.
  - Hỗ trợ bàn lễ tân gán người vãng lai thanh toán tiền mặt và tự động đóng kèo khi đủ người.
  - **44/44 bài test backend tự động đạt PASS 100%**.
- **Frontend**:
  - `match_feed_screen.dart`: Bảng tin kèo thể thao, bộ lọc theo môn và quận huyện, thanh tiến độ tuyển người.
  - `match_checkout_screen.dart`: Tạo bài tuyển người ghép kèo kèm form dự tính chi phí.
- **Tình trạng**: **Logic backend rất vững chắc**.
- ⚠️ **Điểm cần lưu ý (Góp ý của Thầy)**: Khi khách vãng lai (Guest) bấm "Tham gia kèo", app đang chặn lại và chuyển sang màn hình bắt đăng ký số điện thoại qua OTP. Thầy yêu cầu: Khách vãng lai không cần tạo tài khoản thành viên, chỉ cần điền Tên + SĐT liên hệ $\rightarrow$ Đóng cọc ngay $\rightarrow$ Cấp vé QR và lưu ví tạm trên thiết bị đó.

---

### 🔹 Module 5: Thanh Toán Escrow, Vé QR Offline SHA-256 & Hủy Vé (Member 5)
- **Backend**:
  - `PaymentsController.cs` (`/api/payments/create-intent`, `/api/payments/webhook-ipn`, `/api/payments/mock-pay`, `/api/payments/history`).
  - `TicketsController.cs` (`/api/tickets/my-tickets`, `/api/tickets/verify-qr`, `/api/tickets/{id}/cancel`).
  - **Cơ chế Escrow**: Tiền cọc giữ ở trạng thái `Holding`, chỉ giải ngân `Settled` cho chủ sân khi quét QR check-in hợp lệ.
  - **Chữ ký SHA-256 Checksum**: Chống làm giả vé và chống quét lại lần 2 (Replay Attack).
  - **Chính sách phạt bậc thang**: $\ge 4h$ hoàn 100%, $2h - 4h$ hoàn 50%, $< 2h$ phạt 100%. Tiền hoàn được cộng tự động vào `User.WalletBalance`.
  - **19/19 bài test backend tự động đạt PASS 100%**.
- **Frontend**:
  - `my_tickets_screen.dart`: Tab "Vé của tôi", quản lý số dư Ví hoàn tiền & số dư Tạm giữ (Escrow Holding), công tắc "Giả lập Ngoại tuyến SQLite".
  - `payment_checkout_screen.dart`: Đặt cọc & thanh toán qua VNPay Sandbox, MoMo, Ví SportSpot, Thẻ ATM.
  - `ticket_qr_detail_screen.dart`: Hiển thị mã QR động, chữ ký băm SHA-256, xem vé không cần mạng 4G/Wi-Fi nhờ SQLite `offline_bookings`.
  - `qr_scanner_screen.dart`: Quầy lễ tân quét QR giải ngân tiền cho chủ sân.
  - `cancel_ticket_dialog.dart`: Hộp thoại hủy vé đối chiếu 3 mốc hoàn tiền theo thời gian thực.
  - Banner nhắc lịch thi đấu tự động hiển thị trước giờ bóng lăn 2 tiếng.
- **Tình trạng**: **Hoàn chỉnh và ổn định 100%**.

---

## 🎯 3. TỔNG KẾT & ĐÁNH GIÁ MỨC ĐỘ SẴN SÀNG

1. **Về mặt kỹ thuật**: Toàn bộ Solution Backend .NET 8 (5 projects) build thành công 0 Warning, 0 Error. Toàn bộ các bộ test tự động (Backend Module 4, Module 5; Frontend Module 2, 3, 4, 5) đều **PASS 100%**.
2. **Về mặt demo cho Giảng viên**: Nhóm đã có thể demo mượt mà từ Trang chủ $\rightarrow$ Khám phá sân $\rightarrow$ Đặt khung giờ $\rightarrow$ Tìm kèo ghép $\rightarrow$ Thanh toán Escrow & Quét QR Offline.
3. **Các hạng mục cần hoàn thiện thêm theo lời Thầy**:
   - [ ] Bổ sung luồng **Guest Quick Join** (Khách vãng lai tham gia kèo nhanh không cần đăng ký tài khoản).
   - [ ] Bổ sung màn hình **BookingDetailScreen** (Xem đầy đủ chi tiết đơn đặt sân: tiền sân, phụ kiện, cọc, tiền còn lại tại quầy).
