# **TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW & OBJECTIVES)**

### **1. Thông tin chung**

* **Tên dự án:** SportSpot – Multi-Sport Venue Booking & Match-Finding App  
* **Mã môn học:** PRM393 (Mobile Programming)  
* **Nền tảng mục tiêu:** Android (Flutter Cross-Platform)  
* **Đối tượng sử dụng:** Khách hàng cá nhân có nhu cầu tìm kiếm, tra cứu, đặt lịch sân thể thao theo khung giờ (tập trung vào 4 môn: Cầu lông, Pickleball, Bóng đá mini, Bóng rổ) và Nhân viên lễ tân tại sân.

---

### **2. Bối cảnh & Bài toán giải quyết**

* **Thực trạng:** Nhu cầu chơi thể thao phong trào (đặc biệt là Cầu lông và Pickleball) tăng cao. Việc đặt sân qua gọi điện thoại hoặc nhắn tin fanpage thường gặp bất cập: không nắm được khung giờ còn trống thực tế, tốn thời gian xác nhận, dễ trùng lịch, khó rủ đủ người chơi (thiếu vãng lai) và quên giờ chơi.  
* **Giải pháp:** Ứng dụng di động giúp người chơi:
  * Tra cứu trực quan tình trạng sân theo ngày/giờ và đặt chỗ nhanh chóng (chống trùng lịch).
  * Hỗ trợ tìm kiếm quanh vị trí hiện tại theo bán kính GPS (1–15km).
  * Kênh ghép trận và tuyển vãng lai 2 chiều (qua App và tại quầy sân) có tự động chia tiền sòng phẳng.
  * Lưu trữ vé điện tử offline (SQLite) có mã QR động để check-in nhận sân ngay cả khi không có kết nối mạng.
  * Tự động gửi thông báo cục bộ (Local Notifications) nhắc nhở trước trận đấu 2 tiếng.

---

### **3. Mục tiêu dự án**

* Xây dựng ứng dụng di động hoàn chỉnh bám sát 100% chuẩn đầu ra (CLOs) của môn PRM393.  
* Cung cấp trải nghiệm đặt lịch sân thể thao tinh gọn, trực quan, không phát sinh lỗi luồng trong quá trình demo.  
* Đảm bảo tính khả dụng cao bằng cơ chế lưu trữ vé offline (SQLite), mã QR Check-in ngoại tuyến và thông báo cục bộ (Local Notifications).

---

### **4. Phạm vi tính năng (Scope of Work)**

Cả nhóm tập trung 100% nguồn lực hoàn thành các module sau để đảm bảo app mượt mà và bao phủ trọn vẹn tiêu chí chấm điểm:

* **Module 1: Khám phá & Tìm kiếm (Home & Discovery)**  
  * Hiển thị banner các chương trình ưu đãi hoặc cụm sân nổi bật (dùng slider tự động trượt).  
  * Bộ lọc nhanh theo 4 bộ môn thể thao chính: *Cầu lông*, *Pickleball*, *Bóng đá mini*, *Bóng rổ*.  
  * Tìm kiếm cụm sân theo tên hoặc khu vực, hỗ trợ tính khoảng cách GPS thực tế từ người dùng đến cụm sân (bán kính 1–15km).  
  * Mở nhanh ứng dụng bản đồ ngoài (Google Maps) chỉ đường đến sân hoặc gọi điện hotline.
* **Module 2: Chi tiết cụm sân & Đặt lịch (Venue Detail & Booking Flow)**  
  * Hiển thị thông tin chi tiết cụm sân: địa chỉ cụ thể, danh sách tiện ích, bảng giá thường và cao điểm.  
  * Bộ chọn ngày (Date Picker dạng thanh trượt ngang 7 ngày).  
  * Lưới khung giờ (Time Slots Grid) hiển thị trạng thái trực quan: *Trống (xanh)*, *Đã đặt (xám - khóa bấm)*, *Đang chọn (cam)*.  
  * Ràng buộc đặt tối đa 3 slot liên tiếp và cơ chế chống trùng lịch (Concurrency Check - HTTP 409).  
  * Màn hình tóm tắt đơn đặt (Review Booking): tính tiền sân, chọn dịch vụ thuê/mua dụng cụ đi kèm, đặt cọc và phương thức thanh toán.  
* **Module 3: Vé điện tử & Truy cập Offline (My Bookings & SQLite Storage)**  
  * Danh sách vé đã đặt chia theo trạng thái: *Sắp diễn ra*, *Đã hoàn thành*, *Đã hủy*.  
  * Chi tiết vé hiển thị thông tin trận đấu và mã **QR Code động riêng biệt** kèm mã xác thực checksum chống gian lận.  
  * **Cơ chế hoạt động offline:** Dữ liệu vé sau khi đặt thành công sẽ tự động ghi vào SQLite trong máy. Người dùng có thể tắt hoàn toàn mạng 4G/Wi-Fi mà vẫn mở vé và hiển thị mã QR cho nhân viên sân đối soát.  
* **Module 4: Nhắc hẹn & Cá nhân hóa (Notifications & Profile)**  
  * Hệ thống Local Notification tự động kích hoạt trước giờ thi đấu 2 tiếng để nhắc nhở người dùng chuẩn bị.  
  * Danh sách sân yêu thích (Favorites): cho phép thả tim để lưu sân quen thuộc vào bộ nhớ cục bộ SQLite.  
  * Quản lý thông tin tài khoản, xem số dư ví hoàn cọc/hủy trận (`wallet_balance`) và cấu hình bộ môn yêu thích để nhận thông báo tìm kèo.
* **Module 5: Tuyển vãng lai 2 chiều & Tự động chia tiền (Open Match & Dual Recruitment)**  
  * Cho phép Host khi đặt sân mở bài tuyển vãng lai: nhập số người dự kiến và số người cần tìm thêm.  
  * Hệ thống tự động tính chi phí chia đều theo đầu người; khách vãng lai đăng ký tham gia thì tiền tự động trừ vào tổng hóa đơn của Host.  
  * Hỗ trợ Lễ tân gán khách lẻ vãng lai tại quầy vào ca đấu còn trống chỗ.  
  * Cơ chế hủy slot và hoàn tiền linh hoạt theo mốc thời gian (trước 4 tiếng, 2–4 tiếng, dưới 1 tiếng).
* **Module 6: Dịch vụ gia tăng & Vận hành tại sân (Add-on Services & Staff Check-in)**  
  * Đặt trước đồ thuê (vợt, giày, áo tập) và đồ mua (nước uống, quả cầu, bóng) tích hợp thẳng vào quy trình thanh toán.  
  * Màn hình quét mã QR Check-in bằng camera dành cho nhân viên lễ tân (`mobile_scanner`) để xác nhận khách đến nhận sân.
