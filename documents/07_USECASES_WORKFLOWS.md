# 🔄 Sơ Đồ Use Case & Quy Trình Nghiệp Vụ (Use Cases & Workflows)

Tài liệu cung cấp sơ đồ Use Case tổng quát và các sơ đồ tuần tự (**Sequence Diagrams**) mô phỏng chi tiết 4 luồng vận hành cốt lõi của nền tảng **SportSpot**.

---

## 1. Sơ đồ Use Case Tổng Quát (Overall Use Case Diagram)

```mermaid
flowchart LR
    Guest(["👤 Khách Vãng Lai (Guest)"])
    User(["👤 Khách Hàng / Host (User)"])
    Staff(["🏢 Lễ Tân Quầy (Venue Staff)"])
    SysStaff(["👔 Nhân Viên Vận Hành (System Staff)"])
    SysAdmin(["💻 Quản Trị Viên (System Admin)"])
    PaymentGW(["💳 Cổng Thanh Toán"])

    subgraph GuestUseCases ["Phân hệ Khách vãng lai & Xác thực"]
        UC01["UC01: Tra cứu sân & Xem lịch trống"]
        UC02["UC02: Xem danh sách kèo tuyển vãng lai"]
        UC03["UC03: Đăng ký xác thực qua SĐT & OTP"]
    end

    subgraph CoreUseCases ["Phân hệ Đặt sân, Tuyển vãng lai & Dịch vụ"]
        UC04["UC04: Cài đặt chế độ Tìm kèo & Môn thể thao (5-10km)"]
        UC05["UC05: Đặt sân & Chọn tùy chọn Tuyển vãng lai"]
        UC06["UC06: Thuê & Mua phụ kiện (Vợt, Cầu, Nước)"]
        UC07["UC07: Tham gia kèo vãng lai (Trả tiền chia đều qua Cổng thanh toán)"]
        UC08["UC08: Chủ động bấm Dừng tuyển vãng lai"]
        UC09["UC09: Xử lý khi thiếu người (Tiếp tục tìm / Hủy hoàn tiền)"]
        UC10["UC10: Hủy tham gia kèo (Phạt bậc thang 4h / 2h / 1h)"]
        UC11["UC11: Xem vé điện tử ngoại tuyến (Mã QR riêng cho từng thành viên)"]
    end

    subgraph StaffUseCases ["Phân hệ Lễ tân sân & Quản trị"]
        UC12["UC12: Bấm nút Gán khách vãng lai tại quầy (Trừ tiền sân)"]
        UC13["UC13: Quét QR check-in & Giao đồ thuê"]
        UC14["UC14: Duyệt cụm sân mới đăng ký"]
        UC15["UC15: Xem Dashboard & Xuất báo cáo dữ liệu"]
    end

    Guest --> UC01
    Guest --> UC02
    Guest --> UC03

    User --> UC04
    User --> UC05
    User --> UC06
    User --> UC07
    User --> UC08
    User --> UC09
    User --> UC10
    User --> UC11

    UC05 <--> PaymentGW
    UC07 <--> PaymentGW

    Staff --> UC12
    Staff --> UC13
    SysStaff --> UC14
    SysAdmin --> UC15
```

---

## 2. Các Luồng Quy Trình Tuần Tự (Sequence Diagrams)

### 2.1. Luồng Xác thực Khách vãng lai (`Guest` $ightarrow$ `User` via Phone + OTP)
```mermaid
sequenceDiagram
    autonumber
    actor Guest as Khách vãng lai (Guest)
    participant UI as Flutter Mobile App
    participant API as Backend Web API (.NET 8)
    participant SMS as SMS / OTP Gateway
    participant DB as Supabase PostgreSQL

    Guest->>UI: Xem danh sách kèo mở, bấm "Tham gia kèo"
    UI->>UI: Phát hiện chưa có Token phiên (Guest Mode)
    UI-->>Guest: Hiển thị form: "Vui lòng nhập SĐT để tiếp tục"
    Guest->>UI: Nhập SĐT: 0901234567
    UI->>API: POST /api/auth/send-otp (phoneNumber)
    API->>SMS: Dispatch 6-digit OTP to 0901234567
    SMS-->>Guest: Tin nhắn SMS: "Mã OTP SportSpot của bạn là 839201"
    Guest->>UI: Nhập mã OTP 839201
    UI->>API: POST /api/auth/verify-otp (phoneNumber, otp)
    API->>DB: Kiểm tra hoặc tạo tài khoản mới trong "Users"
    API-->>UI: 200 OK (JWT Token, User Profile)
    UI->>UI: Nâng cấp phiên lên Registered User & Lưu user_session SQLite
    UI-->>Guest: Tự động đưa thẳng vào màn hình Thanh toán tham gia kèo
```

### 2.2. Luồng Tuyển Vãng Lai 2 Chiều & Tự Động Trừ Tiền Sân
```mermaid
sequenceDiagram
    autonumber
    actor Host as Đội trưởng (Host)
    participant UI as Flutter App (Host)
    participant API as Backend Web API (.NET 8)
    participant DB as Supabase PostgreSQL
    actor Guest as Khách vãng lai (App)
    actor Staff as Lễ tân tại quầy sân

    Host->>UI: Đặt sân 600.000đ, cọc 300.000đ, tick "Tuyển vãng lai"
    Host->>UI: Nhập: Tổng người = 10, Cần tìm = 4 vãng lai
    UI->>UI: Tự động tính: Giá mỗi vãng lai = 600.000 / 10 = 60.000đ
    Host->>UI: Xác nhận cọc 300.000đ qua VNPay
    UI->>API: POST /api/bookings/create (needed=4, cost=60k, remaining=300k)
    API->>DB: INSERT Booking & OpenMatch (status='Open')
    
    par Kênh 1: Tuyển Online qua App
        API-->>Guest: Push Notification (Bán kính 5-10km & Đúng môn): "Tuyển 4 vãng lai, 60k/người"
        Guest->>API: POST /api/matches/{id}/join (Thanh toán 60.000đ qua VNPay)
        API->>DB: INSERT MatchMember & remaining_balance = 300k - 60k = 240k
        API-->>Guest: Cấp mã vé QR riêng cho Khách vãng lai
    and Kênh 2: Hỗ trợ tại Quầy Tiếp Tân Offline
        API-->>Staff: Màn hình lễ tân hiện cờ: "Sân 1 đang tuyển vãng lai"
        Note over Staff: Khách lẻ tới quầy hỏi trận, đóng 60.000đ tiền mặt
        Staff->>API: POST /api/matches/{id}/assign-walk-in (Bấm nút gán tại quầy)
        API->>DB: INSERT MatchMember (Type: 'WalkInAtDesk') & remaining_balance = 240k - 60k = 180k
    end

    opt Host chủ động dừng tuyển sớm
        Host->>UI: Bấm nút "Dừng tuyển" (vì đã rủ đủ bạn bè)
        UI->>API: PUT /api/matches/{id}/stop-recruiting
        API->>DB: UPDATE OpenMatch SET status = 'Stopped'
        API-->>UI: Thông báo: Đã dừng tuyển vãng lai thành công
    end
```

### 2.3. Luồng Xử Lý Khi Thiếu Người & Phạt Hủy Kèo Bậc Thang
```mermaid
sequenceDiagram
    autonumber
    actor Host as Đội trưởng (Host)
    participant API as Backend Web API
    participant PGW as Payment Gateway
    participant DB as PostgreSQL
    actor Guest as Khách vãng lai

    Note over API: Trước giờ thi đấu 2 tiếng, OpenMatch vẫn thiếu 2 người
    API-->>Host: Cảnh báo: "Kèo còn thiếu 2 người. Bạn muốn tiếp tục tìm hay hủy trận?"
    alt Host chọn Hủy trận (Do thiếu người)
        Host->>API: POST /api/matches/{id}/cancel-due-to-shortage
        API->>DB: UPDATE OpenMatch & Booking SET status='Cancelled'
        Note over API,DB: Phạt cọc Host (chuyển bồi thường cho Chủ sân)
        API->>PGW: Hoàn tiền 100% cho tất cả Khách vãng lai đã tham gia
        PGW-->>Guest: Hoàn tiền 60.000đ về tài khoản ngân hàng / ví
    end

    Note over Guest: Trường hợp Khách vãng lai chủ động Hủy tham gia
    alt Hủy trước giờ đấu >= 4 tiếng
        Guest->>API: POST /api/matches/{id}/leave
        API->>PGW: Hoàn 100% tiền cho Khách vãng lai
        API->>DB: Mở lại 1 slot trống trên OpenMatch & Bắn lại thông báo
    else Hủy trước giờ đấu từ 2 - 4 tiếng
        Guest->>API: POST /api/matches/{id}/leave
        API->>PGW: Hoàn 50% tiền cho Khách vãng lai (Phạt 50% bù cho Host)
        API->>DB: Mở lại 1 slot trống trên OpenMatch
    else Hủy trước giờ đấu < 1 tiếng
        Guest->>API: POST /api/matches/{id}/leave
        Note over API,DB: Phạt 100% (Không hoàn tiền, trừ thẳng vào tiền sân của Host)
    end
```

### 2.4. Luồng Quét QR Check-in Tại Sân Cho Từng Thành Viên (Offline Mode)
```mermaid
sequenceDiagram
    autonumber
    actor Host as Đội trưởng
    actor Guest as Khách vãng lai
    actor Staff as Lễ tân sân
    participant API as Backend Web API
    participant DB as PostgreSQL

    Host->>Staff: Mở app (Offline), xuất trình mã QR vé Host
    Staff->>API: Quét QR vé Host
    API-->>Staff: Xác nhận: "Vé Host hợp lệ - Sân 5A (Đã cọc 300k, còn thiếu 180k)"
    Host->>Staff: Thanh toán nốt số dư 180k tiền mặt
    Staff->>API: Xác nhận thu đủ tiền sân
    
    Guest->>Staff: Đến sân, xuất trình mã QR vé Vãng lai
    Staff->>API: Quét QR vé Vãng lai
    API-->>Staff: Xác nhận: "Khách vãng lai hợp lệ - Đã thanh toán 60k - Vào Sân 5A"
    Staff-->>Guest: Chỉ đường vào sân gặp Host
    Note over Host,Guest: Hai đội thi đấu vui vẻ. Sau trận, tự thỏa thuận tiền nước / đá 7-3 ngoài đời
```
