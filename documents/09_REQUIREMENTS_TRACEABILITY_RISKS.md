# 📊 Ma Trận Truy Vết Yêu Cầu & Quản Lý Rủi Ro (RTM & Risk Management)

---

## 1. Ma trận Truy vết Yêu cầu (Requirements Traceability Matrix - RTM)

Bảng đối chiếu chéo đảm bảo 100% tính năng được thiết kế nhất quán từ Business Goal $ightarrow$ Functional Requirement $ightarrow$ Use Case $ightarrow$ API Endpoint $ightarrow$ Bảng Cơ sở dữ liệu:

| Feature ID | Tên tính năng | Use Case ID | API Endpoint liên kết | Bảng Database (Cloud / Local) | Quy tắc nghiệp vụ (BR) |
| :---: | :--- | :---: | :--- | :--- | :--- |
| **F01** | Xác thực Guest & Phone OTP | `UC01`, `UC03` | `POST /api/auth/send-otp`<br>`POST /api/auth/verify-otp` | `Users`<br>`user_session` (SQLite) | `BR-AUTH-01`<br>`BR-AUTH-03` |
| **F03** | Khám phá & Bộ lọc thể thao | `UC01` | `GET /api/venues` | `Sports`, `Venues` | N/A |
| **F04** | Tìm kiếm khoanh vùng bán kính (5-10km) | `UC04` | `GET /api/venues?radiusKm=...` | `Venues` (Lat/Long) | `BR-NOTI-01` |
| **F05** | Chi tiết cụm sân & Dịch vụ | `UC05` | `GET /api/venues/{id}` | `SubVenues`, `Services` | N/A |
| **F06** | Chọn lưới slot giờ liên tiếp | `UC05` | `GET /api/venues/.../slots` | `TimeSlots`, `BookingDetails` | `BR-SLOT-01`<br>`BR-SLOT-02` |
| **F07** | Đặt sân & Chống trùng lịch (409) | `UC05` | `POST /api/bookings` | `Bookings`, `BookingDetails` | `BR-SLOT-04` |
| **F08** | Vé điện tử ngoại tuyến (Offline QR) | `UC11` | `GET /api/bookings/my-tickets` | `offline_bookings` (SQLite) | `BR-TKT-01`<br>`BR-TKT-02` |
| **F09** | Nhắc lịch trận đấu (Local Notification) | `UC11` | N/A (On-device Alarm) | `offline_bookings` (SQLite) | `BR-NOTI-02` |
| **F10** | Dòng tiền & Cổng thanh toán (Escrow) | `UC05`, `UC07` | `POST /api/bookings`<br>`POST /api/payment/webhook` | `Transactions` (`Holding` $ightarrow$ `Settled`) | `BR-PAY-01`<br>`BR-PAY-03` |
| **F11** | Tuyển vãng lai 2 chiều & Tự chia tiền | `UC05`, `UC07`, `UC12` | `POST /api/matches/join`<br>`POST /api/matches/.../assign` | `OpenMatches`, `MatchMembers`, `Bookings` (`remaining_balance`) | `BR-RECRUIT-01`<br>đến `08` |
| **F12** | Thuê & Mua phụ kiện tại sân | `UC06` | `POST /api/bookings` (services) | `Services`, `BookingServices` | N/A |
| **F13** | Giao diện Quầy lễ tân & Quét mã QR | `UC12`, `UC13` | `POST /api/staff/check-in` | `MatchMembers`, `Bookings` | `BR-TKT-01` |

---

## 2. Kế hoạch Quản lý Rủi ro Dự án (Project Risk Management Matrix)

| ID | Nguy cơ / Rủi ro tiềm ẩn (Risk) | Khả năng (L) | Mức ảnh hưởng (I) | Mức rủi ro | Biện pháp phòng ngừa & Xử lý (Mitigation Plan) |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **R01** | **Rủi ro mất sóng mạng tại sân:** Tầng hầm/nhà thi đấu mất 4G khiến khách không mở được vé QR. | **Cao** | **Nghiêm trọng** | 🔴 **Cao** | Áp dụng kiến trúc **Offline-first**: Lưu vé ngay vào SQLite sau khi đặt; sinh mã QR động trực tiếp tại thiết bị bằng `qr_flutter` không gọi API. |
| **R02** | **Rủi ro trùng lịch (Double Booking):** 2 người cùng bấm đặt 1 slot trong cùng 1 giây. | **Trung bình** | **Nghiêm trọng** | 🔴 **Cao** | Sử dụng **Database Transaction** và Unique Constraint `UQ_BookingSlot (booking_id, slot_id)`. Trả về mã lỗi HTTP `409 Conflict` cho người đến sau. |
| **R03** | **Rủi ro bùng kèo vãng lai:** Khách vãng lai bấm tham gia miệng rồi không đến. | **Cao** | **Trung bình** | 🟡 **Vừa** | **Bắt buộc thanh toán tiền chia đều ngay khi tham gia** qua Cổng thanh toán. Áp dụng chính sách phạt hủy bậc thang ($4h/2h/1h$). |
| **R04** | **Rủi ro Spam thông báo tìm kèo:** Quá nhiều thông báo làm phiền người dùng dẫn đến gỡ app. | **Trung bình** | **Trung bình** | 🟡 **Vừa** | Chỉ gửi thông báo khi User **bật chế độ tìm kèo**, chọn **đúng môn yêu thích** và nằm trong **bán kính 5-10km**. |
| **R05** | **Rủi ro lỗi Cổng thanh toán:** Lỗi mạng hoặc sandbox bên thứ 3 gián đoạn buổi demo. | **Thấp** | **Nghiêm trọng** | 🟡 **Vừa** | Xây dựng chế độ thanh toán giả lập dự phòng (Simulated Mode / Cash at Venue) kích hoạt bằng cấu hình `appsettings.json` khi demo. |
