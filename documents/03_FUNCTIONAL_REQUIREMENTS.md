# 📋 Đặc Tả Yêu Cầu Chức Năng (Functional Requirements)

Tài liệu đặc tả chi tiết 14 Module tính năng của nền tảng **SportSpot**, viết theo chuẩn User Story kèm tiêu chí nghiệm thu **Acceptance Criteria (Gherkin style: Given-When-Then)**.

---

## MODULE 1: XÁC THỰC, PHÂN QUYỀN & TRẢI NGHIỆM GUEST

### F01: Xác thực Người dùng & Trải nghiệm Guest (MoSCoW: Must-Have)
* **User Story:**
  * Là một `Khách vãng lai (Guest)`, tôi muốn xem danh mục sân, lịch trống và các kèo đang tuyển mà không bị bắt đăng nhập để trải nghiệm ứng dụng dễ dàng.
  * Là một `Người chơi`, tôi muốn đăng ký/đăng nhập nhanh bằng Số điện thoại và mã OTP để đặt sân hoặc tham gia kèo an toàn.
* **Tiêu chí chấp nhận (Acceptance Criteria):**
  * `AC-01 (Guest Mode):` Khi mở app lần đầu, người dùng bấm "Khám phá ngay (Khách vãng lai)" $ightarrow$ Được chuyển thẳng vào Trang chủ mà không cần nhập mật khẩu.
  * `AC-02 (OTP Trigger):` Khi Guest bấm "Đặt sân" hoặc "Tham gia kèo" $ightarrow$ Hệ thống hiển thị BottomSheet yêu cầu nhập Số điện thoại Việt Nam hợp lệ (10 chữ số).
  * `AC-03 (OTP Verification):` Hệ thống gửi mã OTP 6 số ngẫu nhiên qua SMS/Firebase, đếm ngược 120s. Nhập đúng $ightarrow$ Tự động tạo/đăng nhập tài khoản, cấp JWT token, lưu vào `user_session` SQLite và chuyển tiếp vào luồng thao tác.

### F02: Hồ sơ Cá nhân & Cài đặt Tìm kèo (MoSCoW: Should-Have)
* **User Story:** Là một `Người chơi`, tôi muốn quản lý thông tin cá nhân và bật chế độ "Tìm kèo" theo môn thể thao yêu thích để nhận thông báo trận đấu gần mình.
* **Acceptance Criteria:**
  * `AC-04:` Cho phép User cập nhật Họ tên, Email liên hệ.
  * `AC-05 (Find-match Settings):` Công tắc gạt "Chế độ tìm kèo (Find-Match Mode)": Khi bật ON, cho phép chọn môn thể thao (Cầu lông, Bóng đá mini, Pickleball, Bóng rổ) và chọn bán kính quét (mặc định 5-10km). Trạng thái được đồng bộ lên Cloud và lưu vào `app_settings` SQLite.

---

## MODULE 2: KHÁM PHÁ & ĐỊNH VỊ BÁN KÍNH

### F03: Trang Chủ & Bộ Lọc Thể Thao (MoSCoW: Must-Have)
* **User Story:** Là một `Người chơi`, tôi muốn lướt xem các chương trình ưu đãi và lọc nhanh cụm sân theo môn thể thao để chọn sân mong muốn.
* **Acceptance Criteria:**
  * `AC-06:` Banner trượt tự động (`CarouselSlider`) chuyển slide mỗi 4 giây, tạm dừng khi người dùng chạm giữ.
  * `AC-07:` 4 chip môn thể thao nằm ngang: Cầu lông, Pickleball, Bóng đá mini, Bóng rổ. Bấm chọn môn nào thì danh sách thẻ sân bên dưới tự lọc theo môn đó mà không reload màn hình.

### F04: Tìm Kiếm Khoanh Vùng Bán Kính (MoSCoW: Should-Have)
* **User Story:** Là một `Người chơi`, tôi muốn tìm kiếm sân bóng/sân cầu lông trong bán kính 5-10km hoặc theo Quận/Huyện để chọn sân gần nhất.
* **Acceptance Criteria:**
  * `AC-08 (Search Debounce):` Ô tìm kiếm tự động lọc kết quả sau 400ms ngừng gõ phím.
  * `AC-09 (Radius Calculation):` Ứng dụng tính khoảng cách từ vị trí GPS của User đến cụm sân bằng công thức Haversine và hiển thị huy hiệu khoảng cách (vd: `📍 2.5 km`).

### F05: Chi Tiết Cụm Sân & Tiện Ích (MoSCoW: Must-Have)
* **User Story:** Là một `Người chơi`, tôi muốn xem hình ảnh thực tế, tiện ích, bảng giá và số hotline của sân trước khi đặt chỗ.
* **Acceptance Criteria:**
  * `AC-10:` Hiển thị danh sách sân con (`SubVenues`), ảnh sân thực tế qua Cloudinary CDN, danh sách tiện ích (Bãi xe, Căn tin, Tắm nóng lạnh, Thuê vợt).
  * `AC-11:` Nút "Gọi chủ sân" mở trực tiếp ứng dụng Dialer điện thoại; nút "Xem chỉ đường" mở ứng dụng Google Maps ngoài theo tọa độ sân.

---

## MODULE 3: ĐẶT LỊCH & TUYỂN VÃNG LAI 2 CHIỀU

### F06: Tra Cứu & Chọn Lưới Khung Giờ (MoSCoW: Must-Have)
* **User Story:** Là một `Đội trưởng`, tôi muốn chọn ngày thi đấu và chọn các khung giờ còn trống trên lưới trực quan để giữ sân.
* **Acceptance Criteria:**
  * `AC-12 (Date Range):` Thanh trượt chọn ngày trong 7 ngày tới ($T$ đến $T+6$). Vô hiệu hóa các slot giờ đã qua trong ngày hôm nay.
  * `AC-13 (Slots Matrix):` Lưới slot 60 phút hiển thị 3 màu: Xanh lá (Trống), Xanh dương/Cam (Đang chọn), Xám (Đã kín/Đã qua).
  * `AC-14 (Consecutive Rule):` Cho phép chọn tối đa 3 slot (3 tiếng) và **bắt buộc các slot phải liên tiếp nhau**. Bấm chọn slot ngắt quãng $ightarrow$ Hiển thị Toast cảnh báo: *"Vui lòng chọn các khung giờ liên tiếp nhau"*.
  * `AC-15 (Flexibility):` **Không áp đặt giới hạn sức chứa cứng (No hard capacity constraints)**, người đại diện tự do điều phối số lượng thành viên thực tế.

### F07: Xác Nhận Đơn Đặt & Chống Trùng Lịch (MoSCoW: Must-Have)
* **User Story:** Là một `Đội trưởng`, tôi muốn xác nhận đặt sân an toàn và không bị trùng lịch với người khác.
* **Acceptance Criteria:**
  * `AC-16 (Concurrency Check):` Khi bấm "Xác nhận đặt sân", Backend API kiểm tra lại tính khả dụng của slot trong Database Transaction:
    * Nếu đã bị đặt: Trả về mã lỗi `409 Conflict`, báo lỗi *"Khung giờ này vừa có người đặt. Vui lòng chọn giờ khác!"* và đưa user về lưới slot.
    * Nếu còn trống: Tạo bản ghi Booking thành công, sinh mã đặt chỗ duy nhất `booking_code` (format: `SP-XXXXXX`).

### F11: Tuyển Vãng Lai 2 Chiều & Chia Tiền Tự Động (MoSCoW: Should-Have)
* **User Story:** Là một `Đội trưởng (Host)`, tôi muốn bật tùy chọn tuyển vãng lai để hệ thống và sân cùng hỗ trợ tìm người, đồng thời tự chia đều tiền sân minh bạch.
* **Acceptance Criteria:**
  * `AC-17 (Setup Recruitment):` Khi đặt sân, Host tick chọn checkbox *"Tuyển vãng lai"*, nhập: *Tổng số người dự kiến* (vd: 10) và *Số lượng vãng lai cần tuyển* (vd: 4).
  * `AC-18 (Auto-split Cost):` Hệ thống tự động tính chi phí mỗi vãng lai:
    $$	ext{cost\_per\_person} = 	ext{ROUND}\left(rac{	ext{Tiền sân}}{	ext{Tổng số người dự kiến}}ight)$$
  * `AC-19 (Online Recruitment):` Bài tuyển được đẩy lên tab "Kèo vãng lai gần bạn" và bắn notification cho các user trong bán kính 5-10km có cùng môn thể thao. Vãng lai bấm tham gia, thanh toán tiền qua Cổng thanh toán $ightarrow$ Tiền này tự động trừ vào số tiền sân còn lại mà Host phải đóng $ightarrow$ Cấp mã QR vé riêng cho vãng lai.
  * `AC-20 (Offline Desk Assignment):` Màn hình Lễ tân sân nhận cờ ca đấu thiếu người. Lễ tân thu tiền mặt từ khách lẻ và bấm nút **"Gán vãng lai tại quầy"** $ightarrow$ Hệ thống tự trừ tiếp vào tiền sân của Host.
  * `AC-21 (Stop Recruiting):` Tự động đóng tuyển khi đủ người; hoặc Host có nút bấm **"Dừng tuyển"** thủ công bất kỳ lúc nào.
  * `AC-22 (Shortage Handling):` Trước giờ đá 2 tiếng nếu thiếu người: Host được chọn (1) Tiếp tục tìm đến sát giờ (tự bù tiền thiếu), hoặc (2) Bấm hủy trận (Host chịu phí phạt cọc; vãng lai đã đóng tiền được **hoàn trả 100%**).
  * `AC-23 (Tiered Cancellation):` Vãng lai hủy tham gia: $\ge 4h$ (hoàn 100%, mở lại 1 slot trống); $2-4h$ (hoàn 50%, phạt 50% bù cho Host); $< 1h$ (phạt 100%, trừ vào tiền sân).

---

## MODULE 4: DỊCH VỤ GIA TĂNG THUÊ & MUA ĐỒ

### F12: Thuê & Mua Dụng Cụ Tại Sân (MoSCoW: Should-Have)
* **User Story:** Là một `Người chơi`, tôi muốn đặt thuê vợt, giày và mua ống cầu, nước uống ngay trong đơn đặt sân để không mất thời gian chuẩn bị.
* **Acceptance Criteria:**
  * `AC-24:` Tích hợp mục "Dịch vụ phụ trợ" trong màn hình Checkout: Đồ thuê (Vợt cầu lông, vợt pickleball, áo pitch) và Đồ bán (Ống cầu, bóng, vớ, nước giải khát).
  * `AC-25:` Cho phép tăng giảm số lượng (+ / -). Hệ thống tự động cộng dồn: $	ext{Tổng thanh toán} = 	ext{Tiền sân} + 	ext{Tiền thuê đồ} + 	ext{Tiền mua đồ}$.

---

## MODULE 5: DÒNG TIỀN, THANH TOÁN & VÉ NGOẠI TUYẾN

### F10: Dòng Tiền & Cổng Thanh Toán (MoSCoW: Must-Have)
* **User Story:** Là một `Người chơi`, tôi muốn thanh toán cọc an toàn qua ví điện tử và biết rõ tiền cọc của mình được bảo đảm.
* **Acceptance Criteria:**
  * `AC-26 (Deposit Payment):` Hỗ trợ thanh toán cọc tối thiểu 30% hoặc 100% qua Cổng thanh toán VNPay / MoMo.
  * `AC-27 (Escrow Holding):` Tiền cọc được hệ thống SportSpot giữ ở trạng thái `Holding`. Sau khi quét QR check-in tại sân thành công, hệ thống quyết toán (Payout) cho Chủ sân (sau khi trừ phí sàn).
  * `AC-28 (Refund Policy):` Host hủy sân trước $\ge 4$ tiếng $ightarrow$ Hoàn 100% tiền cọc; Hủy $< 4$ tiếng $ightarrow$ Không hoàn cọc (tiền cọc bồi thường cho chủ sân).

### F08: Vé Điện Tử Ngoại Tuyến (Offline QR Pass) (MoSCoW: Must-Have)
* **User Story:** Là một `Người chơi`, tôi muốn mở vé và quét mã QR check-in tại sân ngay cả khi điện thoại hoàn toàn mất sóng 4G/Wi-Fi.
* **Acceptance Criteria:**
  * `AC-29 (SQLite Sync):` Khi đặt vé hoặc tham gia kèo thành công, dữ liệu vé và chuỗi sinh QR được lưu ngay vào bảng `offline_bookings` trong SQLite máy.
  * `AC-30 (Offline Mode):` Khi ngắt kết nối mạng, mở tab "Vé của tôi", app tự động truy vấn SQLite hiển thị danh sách vé kèm badge "Vé ngoại tuyến".
  * `AC-31 (Dynamic QR):` Render mã QR Code lớn trực tiếp trên thiết bị bằng package `qr_flutter` từ chuỗi: `SPORTSPOT|<booking_code>|<user_id>|<role>`. Host và Vãng lai có mã QR riêng biệt.

### F09: Nhắc Nhở Lịch Thi Đấu Tự Động (MoSCoW: Should-Have)
* **User Story:** Là một `Người chơi`, tôi muốn điện thoại tự động nhắc lịch thi đấu trước 2 tiếng để kịp chuẩn bị đồ đạc và di chuyển.
* **Acceptance Criteria:**
  * `AC-32:` Ứng dụng tự động lập lịch qua `flutter_local_notifications` ngay khi đơn đặt hoàn tất.
  * `AC-33:` Đúng trước giờ bắt đầu trận đấu 2 tiếng, điện thoại bắn thông báo lên thanh trạng thái: *"[SportSpot] Nhắc lịch trận đấu sắp diễn ra!..."*. Bấm vào thông báo mở thẳng màn hình vé QR.
  * `AC-34:` Khi hủy vé hoặc hủy tham gia kèo $ightarrow$ Hệ thống tự động thu hồi lịch hẹn thông báo (`cancel(id)`).

---

## MODULE 6: QUẢN TRỊ & VẬN HÀNH ĐA TẦNG

### F13: Quản Trị Hệ Thống Đa Tầng (MoSCoW: Should-Have)
* **User Story:** Là `Lễ tân sân`, `Nhân viên vận hành` hoặc `Admin`, tôi muốn có giao diện quản trị riêng phù hợp với quyền hạn của mình.
* **Acceptance Criteria:**
  * `AC-35 (Venue Staff Desk):` Giao diện quét mã camera QR của khách; xem danh sách ca đấu thiếu người và bấm nút **"Gán vãng lai tại quầy"**; theo dõi xuất/trả đồ thuê.
  * `AC-36 (System Staff):` Tiếp nhận hồ sơ sân mới đăng ký lên sàn, duyệt hoặc từ chối kèm lý do; tiếp nhận và xử lý khiếu nại của người chơi.
  * `AC-37 (System Admin):` Xem Dashboard phân tích tổng quan số lượt đặt, doanh số cọc, tỷ lệ ghép kèo thành công; xuất dữ liệu báo cáo (Export CSV / Excel).
