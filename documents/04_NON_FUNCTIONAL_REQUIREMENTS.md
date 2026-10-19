# ⚙️ Đặc Tả Yêu Cầu Phi Chức Năng (Non-Functional Requirements - NFR)

Tài liệu quy định các tiêu chuẩn kỹ thuật về hiệu năng, bảo mật, độ tin cậy và khả năng tương thích của nền tảng **SportSpot**.

---

## 1. Hiệu năng hệ thống (Performance Requirements)
* **Thời gian phản hồi API (API Response Time):**
  * Các API tra cứu danh mục, tìm kiếm sân và xem lưới khung giờ phải phản hồi trong thời gian $\le 500ms$ trong điều kiện mạng 4G tiêu chuẩn.
  * API xử lý đặt sân và tạo giao dịch thanh toán phải phản hồi $\le 1.5s$.
* **Tốc độ truy xuất ngoại tuyến (Offline Performance):**
  * Thời gian mở danh sách vé và sinh mã QR Code từ SQLite cục bộ trên thiết bị phải đạt $\le 100ms$ (phản hồi tức thì, không giật lag).
* **Khả năng chịu tải đồng thời (Concurrency Handling):**
  * Hệ thống Backend Web API đảm bảo xử lý tối thiểu 500 yêu cầu đồng thời (concurrent requests) tại các khung giờ cao điểm (16:00 - 18:00 hàng ngày) mà không xảy ra tình trạng deadlock hoặc crash dịch vụ.

---

## 2. Bảo mật & Toàn vẹn dữ liệu (Security & Integrity)
* **Xác thực & Ủy quyền (Authentication & Authorization):**
  * Phiên đăng nhập người dùng được bảo vệ bằng chuẩn **JWT (JSON Web Token)** với thuật ngữ mã hóa HMAC-SHA256. Token có thời hạn hợp lệ 7 ngày và được lưu trữ an toàn trong `flutter_secure_storage` trên thiết bị.
  * Mật khẩu người dùng bắt buộc được băm bằng thuật toán **BCrypt** với work factor $\ge 10$ trước khi lưu trữ vào Database; tuyệt đối không lưu mật khẩu dạng plain text.
  * Mã OTP xác thực số điện thoại gồm 6 chữ số ngẫu nhiên, có thời hạn hiệu lực tối đa 120 giây (2 phút), tự động hủy sau 3 lần nhập sai.
* **Bảo mật API & Khóa bí mật (Secrets Management):**
  * Toàn bộ kênh truyền giữa Mobile Client và Server bắt buộc mã hóa qua giao thức **HTTPS / TLS 1.3**.
  * Các khóa bảo mật dịch vụ ngoài (Cloudinary API Secret, VNPay HashSecret) chỉ được lưu trữ trên biến môi trường của Server .NET, tuyệt đối không hardcode trong mã nguồn Flutter Client.

---

## 3. Độ tin cậy & Tính sẵn sàng (Reliability & Availability)
* **Mô hình Ngoại tuyến cốt lõi (Offline-first Resilience):**
  * Ứng dụng di động không được phép crash hoặc hiển thị màn hình trắng khi mất kết nối mạng.
  * Mọi dữ liệu đặt vé thành công bắt buộc đồng bộ ngay vào SQLite nội bộ. Khi ứng dụng nhận diện không có Internet (`ConnectivityResult.none`), app tự động fallback sang chế độ đọc dữ liệu từ SQLite.
* **Tính nhất quán dữ liệu (Data Consistency & Acid Transactions):**
  * Các thao tác đặt sân, cập nhật slot giờ và ghi nhận giao dịch cọc bắt buộc thực thi trong một **Database Transaction**. Nếu bất kỳ bước nào thất bại, toàn bộ giao dịch phải được Rollback 100% để tránh trạng thái dữ liệu rác.

---

## 4. Trải nghiệm người dùng & Giao diện (Usability & Accessibility)
* **Chuẩn thiết kế Material 3:**
  * Giao diện tuân thủ nguyên tắc thiết kế Material 3 của Google, tối ưu cho thao tác một tay (Thumb Zone Navigation).
  * Độ tương phản màu sắc đạt chuẩn WCAG 2.1 AA (chữ tối màu `#0F172A` trên nền pastel `#E0EEF9` và thẻ trắng `#FFFFFF` giúp nhìn rõ dưới ánh sáng ngoài trời).
* **Bản địa hóa (Localization):**
  * 100% nhãn text, thông báo lỗi, thông điệp hệ thống đều sử dụng tiếng Việt tự nhiên.
  * Định dạng tiền tệ chuẩn Việt Nam (`xxx.000 đ`) và định dạng ngày giờ chuẩn (`DD/MM/YYYY`, `HH:mm`).

---

## 5. Khả năng tương thích thiết bị (Compatibility)
* **Hệ điều hành mục tiêu:** Hỗ trợ từ **Android 10 (API level 29)** đến **Android 14 (API level 34)**.
* **Màn hình thiết bị:** Tương thích linh hoạt (Responsive layout) với các kích thước màn hình phổ biến từ 5.5 inch đến 6.8 inch (độ phân giải từ HD+, FHD+ đến QHD+).
* **Quyền ứng dụng (Permissions):** Chỉ yêu cầu các quyền thực sự cần thiết gồm: `INTERNET`, `POST_NOTIFICATIONS` (Android 13+), `ACCESS_FINE_LOCATION` (tùy chọn cho tìm kiếm bán kính), và `CAMERA` (cho giao diện lễ tân quét QR).
