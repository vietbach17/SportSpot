# 📋 Danh mục tính năng & Phân cấp ưu tiên (System Features & MoSCoW)

**Dự án:** SportSpot – Multi-Sport Venue Booking & Match-Finding Platform  
**Tiêu chuẩn phân loại:** MoSCoW (**Must-Have**, **Should-Have**, **Could-Have**, **Won't-Have**).

---

## 1. Ma trận phân cấp ưu tiên (MoSCoW Matrix)

| Mức độ | Mã module | Tên tính năng | Tầm quan trọng đối với đồ án PRM393 |
| :--- | :--- | :--- | :--- |
| **Must-Have** (Bắt buộc phải có để đạt chuẩn tốt nghiệp môn) | `F01` | Xác thực người dùng (Guest, Phone + OTP, JWT, SQLite Session) | Cốt lõi bảo mật và nhận diện người dùng. |
| | `F03` | Trang chủ, Bộ lọc 4 môn thể thao & Chi tiết cụm sân | Khám phá và hiển thị thông tin sân bãi. |
| | `F06` | Tra cứu ngày, Lựa chọn lưới khung giờ linh hoạt & Slot Holding | Tính năng cốt lõi đặt sân bám sát quy tắc nghiệp vụ. |
| | `F07` | Xác nhận đơn đặt & Chống trùng lịch (Concurrency Check 409) | Đảm bảo tính nhất quán dữ liệu đặt chỗ. |
| | `F08` | Vé điện tử ngoại tuyến (SQLite Storage + Dynamic QR Generator cho từng thành viên) | **Điểm nhấn công nghệ của môn PRM393** (Offline First). |
| | `F10` | Cổng thanh toán điện tử (Payment Gateway - Giữ tiền Escrow & Cọc) | Trả lời câu hỏi "Ai cầm tiền?" theo yêu cầu của hội đồng. |
| **Should-Have** (Cần có để đạt điểm giỏi / xuất sắc) | `F04` | Tìm kiếm khoanh vùng bán kính (1-15km quanh GPS) & Lọc nâng cao | Tăng trải nghiệm định vị người dùng di động. |
| | `F09` | Nhắc nhở lịch thi đấu tự động (Local Notifications trước 2h) | Khai thác tính năng phần cứng của Android OS. |
| | `F11` | Tuyển vãng lai 2 chiều & Tự động chia tiền (Dual Recruitment & Auto-split) | Kênh App + Kênh quầy lễ tân gán khách, tự động trừ tiền sân. |
| | `F12` | Thuê & Mua dụng cụ tại sân (Equipment Rental & Retail) | Tăng tiện ích cho người đặt sân. |
| | `F13` | Cổng vận hành & Quản trị (Lễ tân quét QR check-in, Gán vãng lai quầy) | Phân định rõ vai trò Lễ tân sân và Khách hàng. |
| **Could-Have** (Mở rộng nếu còn thời gian) | `F05-3`| Danh sách sân yêu thích lưu SQLite offline | Cá nhân hóa người dùng khi mất mạng. |
| | `F14` | Đặt sân dài hạn định kỳ theo tháng (Recurring Booking) | Phục vụ các câu lạc bộ cố định. |
| **Won't-Have** (Chủ động loại trừ) | `N/A` | Tự dựng bản đồ GPS turn-by-turn trong app | Dùng Intent (`url_launcher`) mở trực tiếp Google Maps ngoài. |
| | `N/A` | Ép cứng sức chứa tối đa của sân (Hard Capacity Constraint) | Đã loại bỏ để người đại diện tự do điều phối số lượng. |

---

## 2. Danh mục chi tiết các module chức năng (F01 - F14)

### MODULE 1: XÁC THỰC, PHÂN QUYỀN & TRẢI NGHIỆM GUEST
* **F01: Xác thực tài khoản & Quản lý phiên**
  * `F01-1`: Trải nghiệm Khách vãng lai (`Guest`): Được duyệt danh sách sân, xem lịch trống, tìm kèo mở mà không bắt đăng nhập.
  * `F01-2`: Đăng ký tài khoản nhanh qua Số điện thoại + Xác thực mã OTP 6 chữ số (hỗ trợ Mock OTP `123456` trong môi trường kiểm thử).
  * `F01-3`: Đăng nhập bằng Email/SĐT + Mật khẩu. Duy trì phiên đăng nhập trong bảng `user_session` SQLite.
  * `F01-4`: Đăng xuất (xóa phiên `user_session`, giữ nguyên vé offline và lịch sử trong SQLite).

### MODULE 2: KHÁM PHÁ & ĐỊNH VỊ BÁN KÍNH THÔNG MINH
* **F03: Trang chủ & Bộ lọc danh mục**
  * `F03-1`: Banner trượt tự động (`CarouselSlider`) các ưu đãi và giải đấu nổi bật.
  * `F03-2`: Lọc nhanh theo 4 bộ môn: Cầu lông, Pickleball, Bóng đá mini, Bóng rổ.
  * `F03-3`: Danh sách cụm sân (Venue Cards) hiển thị: ảnh, tên, địa chỉ, khoảng giá, rating sao, khoảng cách km.
* **F04: Tìm kiếm khoanh vùng bán kính & Chống spam thông báo**
  * `F04-1`: Thanh tìm kiếm từ khóa theo tên sân, tên đường hoặc Quận/Huyện.
  * `F04-2`: Cấu hình nhận tin tìm kèo: Người dùng bật *"Chế độ tìm kèo (Find-Match Mode)"*, chọn môn thể thao yêu thích và bán kính quét (1km - 15km quanh GPS).
  * `F04-3`: Nhận thông báo đẩy (Notification) chọn lọc: Chỉ thông báo khi có trận đấu mở đúng môn thể thao đã chọn trong bán kính quy định.

### MODULE 3: ĐẶT LỊCH & TUYỂN VÃNG LAI 2 CHIỀU (DUAL RECRUITMENT)
* **F06: Tra cứu & Chọn khung giờ (Time Slots Selection)**
  * `F06-1`: Thanh chọn ngày trượt ngang ($T$ đến $T+6$). Vô hiệu hóa các slot giờ đã qua trong ngày hiện tại.
  * `F06-2`: Lưới slot giờ 3 màu: Trống (xanh), Đang chọn (cam), Đã đặt (xám - khóa).
  * `F06-3`: Giới hạn tối đa 3 slot/đơn và **bắt buộc chọn các slot liên tiếp nhau**.
  * `F06-4`: Tính tiền tự động real-time theo đơn giá thường/cao điểm.
  * `F06-5`: Cơ chế Giữ chỗ tạm thời (Slot Holding): Giữ slot trong 10 phút ở trạng thái `PendingPayment` để chờ thanh toán.
* **F07: Xác nhận đơn đặt & Chống trùng lịch (Booking Checkout & Concurrency)**
  * `F07-1`: Màn hình tóm tắt thông tin: Sân, ngày, slot giờ, tổng tiền sân.
  * `F07-2`: Kiểm tra chống trùng lịch (Concurrency Check - HTTP 409 Conflict). Nếu thành công sinh mã đặt chỗ duy nhất `booking_code` (`SP-XXXXXX`).
* **F11: Cơ chế Tuyển vãng lai 2 chiều & Chia tiền tự động (Open Match Workflow)**
  * `F11-1 (Tùy chọn tuyển vãng lai)`: Khi đặt sân, Host tick chọn *"Tuyển vãng lai"*, nhập: (1) Tổng số người dự kiến tham gia, và (2) Số vãng lai cần tuyển thêm.
  * `F11-2 (Tự động chia tiền)`: Hệ thống tự động tính chi phí mỗi vãng lai = $\text{ROUND}(\text{Tiền sân} / \text{Tổng số người dự kiến})$.
  * `F11-3 (Phát sóng Online qua App)`: Vãng lai bấm "Tham gia" và thanh toán số tiền chia đều qua Cổng thanh toán $\rightarrow$ Tiền này tự động trừ vào số tiền sân còn lại mà Host phải đóng $\rightarrow$ Vãng lai nhận mã QR vé riêng.
  * `F11-4 (Hỗ trợ tại Quầy Offline)`: Lễ tân sân nhận cờ trận thiếu người, thu tiền mặt từ khách lẻ tại quầy và bấm nút **"Gán vãng lai tại quầy"** $\rightarrow$ Hệ thống tự động trừ tiếp vào tiền sân của Host.
  * `F11-5 (Dừng tuyển linh hoạt)`: Hệ thống tự động đóng bài tuyển khi đủ số lượng vãng lai; hoặc Host có thể chủ động bấm **"Dừng tuyển"** thủ công bất kỳ lúc nào nếu đã rủ đủ bạn bè ngoài đời.
  * `F11-6 (Xử lý khi thiếu người)`: Trước giờ đấu 2 tiếng, nếu chưa đủ người, Host được chọn: (1) Tiếp tục tìm đến sát giờ (tự bù tiền nếu thiếu), hoặc (2) Bấm hủy trận (Host chịu phí phạt cọc; hoàn 100% tiền cho các vãng lai đã đăng ký vào `wallet_balance`).
  * `F11-7 (Chính sách vãng lai hủy tham gia)`: Hủy trước $\ge 4\text{h}$ (hoàn 100%, mở lại 1 slot trống); Hủy $2 - 4\text{h}$ (hoàn 50%, phạt 50% bù cho Host); Hủy $< 1\text{h}$ (phạt 100%, trừ vào tiền sân).

### MODULE 4: DỊCH VỤ GIA TĂNG TẠI SÂN (ADD-ON SERVICES)
* **F12: Thuê & Mua dụng cụ tại sân (Equipment Rental & Retail)**
  * `F12-1`: Danh mục đồ cho thuê: Vợt cầu lông, vợt pickleball, giày thể thao, áo tập (tính theo lượt).
  * `F12-2`: Danh mục phụ kiện bán lẻ: Ống cầu, bóng, vớ, nước giải khát.
  * `F12-3`: Tích hợp chọn số lượng phụ kiện vào bước Checkout; tự động tính tổng thanh toán = $\text{Tiền sân} + \text{Tiền thuê đồ} + \text{Tiền mua đồ}$.

### MODULE 5: DÒNG TIỀN, THANH TOÁN & VÉ ĐIỆN TỬ
* **F10: Dòng tiền & Cổng thanh toán (Payment Gateway & Financial Flow)**
  * `F10-1`: Tích hợp Cổng thanh toán trực tuyến (VNPay / MoMo / MockPayment) cho phép thanh toán cọc tối thiểu 30% hoặc toàn bộ 100%.
  * `F10-2`: Mô hình giữ tiền (Escrow): Tiền cọc được hệ thống SportSpot tạm giữ an toàn ở trạng thái `Holding`.
  * `F10-3`: Quyết toán doanh thu (Payout): Sau khi khách quét mã QR check-in tại sân, hệ thống giải ngân tiền cho chủ sân (sau khi trừ phí sàn).
* **F08: Quản lý vé & Xem vé Offline (SQLite Storage)**
  * `F08-1`: Danh sách vé phân loại: Sắp tới, Đã hoàn thành, Đã hủy (bao gồm vé của Host và vé của Vãng lai).
  * `F08-2`: Tự động đồng bộ 2 chiều (Online lưu vào SQLite; Offline tự fallback đọc SQLite).
  * `F08-3`: Chi tiết vé cuống hiển thị mã **QR Code động riêng biệt** cho từng người chơi sinh tại máy kèm Checksum SHA-256 chống gian lận.
  * `F08-4`: Hủy vé trước thời điểm thi đấu tối thiểu 4 tiếng (cập nhật trạng thái và hoàn cọc vào ví `wallet_balance`).
* **F09: Nhắc nhở lịch thi đấu (Local Notifications)**
  * `F09-1`: Lập lịch thông báo tự động ngay sau khi đặt vé hoặc đăng ký kèo qua `flutter_local_notifications`.
  * `F09-2`: Bắn thông báo lên thanh trạng thái trước giờ đấu 2 tiếng. Tự hủy lịch nhắc khi hủy vé.

### MODULE 6: QUẢN TRỊ & VẬN HÀNH TẠI SÂN
* **F13: Quản trị & Vận hành (Venue Staff & Check-in)**
  * `F13-1`: Lễ tân dùng camera quét mã QR check-in của cả Host và Vãng lai, hệ thống xác nhận và ghi nhận `is_checked_in = true`.
  * `F13-2`: Lễ tân xem danh sách ca đấu thiếu người và bấm gán vãng lai tại quầy khi có khách lẻ đến sân.
  * `F13-3`: Quản trị viên xem dashboard tổng quan số đơn đặt và doanh thu cụm sân.
