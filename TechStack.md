## **PHẦN 3: KIẾN TRÚC HỆ THỐNG & TECH STACK CHI TIẾT**

### **1. Phân bổ công nghệ (Technology Stack)**

* **Mobile Client (Frontend):**  
  * Framework: **Flutter SDK** kết hợp **Dart SDK** mới nhất.  
  * IDE khuyến nghị: **Visual Studio Code** (cài các extension: *Flutter*, *Dart*, *Error Lens*) hoặc **Android Studio**.  
  * Môi trường chạy thử: **Android Virtual Device (AVD)** máy ảo chuẩn Android 13/14 trên Android Studio hoặc điện thoại Android thật kết nối qua USB Debugging.  
* **Backend API:**  
  * Framework: **ASP.NET Core Web API (.NET 8)**.  
  * ORM: **Entity Framework Core (EF Core 8)**.  
  * Tài liệu API: **Swagger UI (Swashbuckle / OpenAPI)** giúp kiểm thử API trực quan trước khi tích hợp vào Flutter.  
* **Database tập trung (Shared Cloud Database):**  
  * Nền tảng: **Supabase (Cloud PostgreSQL)**.  
  * *Ưu điểm:* Toàn bộ thành viên dùng chung duy nhất 1 chuỗi `Connection String`. Mọi thay đổi dữ liệu (thêm sân, đổi khung giờ, đặt vé) được đồng bộ tức thì cho tất cả thành viên mà không cần import/export file `.sql` thủ công.

---

### **2. Danh mục thư viện Flutter chính (`pubspec.yaml`)**

Để đảm bảo tương thích và tránh xung đột code, cả nhóm thống nhất sử dụng các thư viện chuẩn sau:

* **Quản lý trạng thái (State Management):** `provider` (gọn nhẹ, chuẩn giáo trình Flutter, dễ tiếp cận).  
* **Giao tiếp mạng (HTTP Client):** `http` (gọi RESTful API từ backend .NET 8).  
* **Cơ sở dữ liệu cục bộ (Offline DB):** `sqflite` + `path` (lưu trữ phiên đăng nhập, vé offline, danh sách yêu thích và cài đặt tìm kèo).  
* **Lưu trữ cặp khóa-giá trị (Key-Value Storage):** `shared_preferences` (lưu access token, cờ cấu hình nhanh).  
* **Thông báo cục bộ:** `flutter_local_notifications` (kích hoạt lịch hẹn thông báo nhắc giờ chơi trước 2 tiếng).  
* **Định vị & Bản đồ:**  
  * `geolocator`: Lấy tọa độ GPS thiết bị, tính khoảng cách đến cụm sân (theo công thức Haversine).  
  * `url_launcher`: Mở ứng dụng ngoài như Google Maps chỉ đường và gọi điện đến số Hotline cụm sân.  
* **Mã QR & Bảo mật:**  
  * `qr_flutter`: Sinh mã QR Code động hiển thị trên cuống vé offline.  
  * `mobile_scanner`: Quét mã QR check-in tại quầy dành cho Lễ tân sân (Venue Staff).  
  * `crypto`: Tạo mã băm Checksum (SHA-256) bảo vệ tính toàn vẹn của mã QR chống giả mạo.  
* **Hỗ trợ giao diện & Tiện ích:**  
  * `intl`: Định dạng ngày tháng chuẩn Việt Nam và tiền tệ VND (`120.000 đ`).  
  * `carousel_slider`: Làm banner trượt tự động tại màn hình Home.

---

### **3. Cấu trúc thư mục Flutter Project (Clean Architecture rút gọn)**

Mã nguồn ứng dụng Flutter sẽ được tổ chức theo cấu trúc chuẩn:

```text
lib/
├── core/
│   ├── constants/       # app_colors.dart, app_styles.dart, app_assets.dart
│   ├── network/         # api_client.dart, api_endpoints.dart
│   └── utils/           # formatters.dart, qr_helper.dart, haversine.dart
├── data/
│   ├── models/          # user_model.dart, venue_model.dart, booking_model.dart, etc.
│   └── services/
│       ├── api_service.dart          # Remote HTTP calls
│       ├── database_helper.dart      # SQLite local database (4 tables)
│       └── notification_service.dart # Local notifications scheduler
├── providers/
│   ├── auth_provider.dart            # Guest, OTP, Login/Logout state
│   ├── venue_provider.dart           # Sports, Venues, Filter, Favorites
│   ├── booking_provider.dart         # Slot selection, Add-ons, Checkout
│   └── ticket_provider.dart          # Offline tickets & QR generator
├── screens/
│   ├── auth/            # login_screen.dart, otp_screen.dart
│   ├── home/            # home_screen.dart, search_screen.dart
│   ├── venue/           # venue_detail_screen.dart, time_slot_picker_screen.dart
│   ├── booking/         # booking_checkout_screen.dart, booking_success_screen.dart
│   ├── tickets/         # my_tickets_screen.dart, ticket_detail_qr_screen.dart
│   └── staff/           # qr_scanner_screen.dart (dành cho lễ tân check-in)
└── widgets/             # venue_card.dart, time_slot_chip.dart, custom_button.dart
```

---

### **4. Cơ chế chia sẻ Backend & Kết nối Môi trường Dev**

* **Kết nối Database:** Chuỗi kết nối đến Cloud Database được cấu hình trong `appsettings.json` của Backend:
  ```json
  "ConnectionStrings": {  
    "DefaultConnection": "Host=aws-0-ap-southeast-1.pooler.supabase.com;Port=6543;Database=postgres;Username=...;Password=..."  
  }
  ```

* **Quy chuẩn định dạng dữ liệu API (Standard API Response):**
  Tất cả các API của ASP.NET Core trả về đồng nhất theo mẫu:
  ```json
  {
    "success": true,
    "statusCode": 200,
    "message": "Thành công",
    "data": { ... }
  }
  ```

* **Chạy API cục bộ cho máy ảo kết nối:**  
  * Khi chạy backend trên máy tính cá nhân, máy ảo Android Emulator truy cập localhost của máy tính thông qua địa chỉ IP đặc thù: `http://10.0.2.2:5000` (hoặc port của dự án .NET).  
  * Cả nhóm cấu hình chung một biến `baseUrl` trong file cấu hình Flutter để dễ dàng chuyển đổi khi chạy trên máy ảo hoặc máy thật (qua mạng LAN/ngrok).

* **Chế độ Giả lập Demo (Mock Mode Strategy):**  
  * **Mock OTP:** Số điện thoại trong môi trường kiểm thử chấp nhận OTP mặc định `123456` để phục vụ demo mượt mà không tốn phí SMS.  
  * **Mock Payment:** Hỗ trợ cổng thanh toán giả lập `MockPayment` trả về kết quả thành công ngay lập tức để không bị phụ thuộc vào IPN webhook khi chạy localhost.
