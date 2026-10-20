# 🏟️ SportSpot – Multi-Sport Venue Booking & Match-Finding Platform

> **Môn học:** PRM393 – Mobile Programming (Học kỳ Fall 2026 – Đại học FPT)  
> **Nhóm thực hiện:** Nhóm 2 (5 thành viên)  
> **Tech Stack:** Flutter 3.x (`frontend/`) • ASP.NET Core Web API (.NET 8 - 3 Layers + Repository Pattern) • Supabase PostgreSQL • SQLite Offline-first

---

## 🌟 Giới Thiệu Ngắn Gọn Dự Án

**SportSpot** là nền tảng di động đặt lịch sân thể thao phong trào (Cầu lông, Pickleball, Bóng đá mini, Bóng rổ) giải quyết 3 bài toán cốt lõi:
1. **Đặt sân trực quan & Chống trùng lịch:** Tra cứu lưới khung giờ trống theo thời gian thực, tìm kiếm cụm sân quanh vị trí GPS (Haversine 5–10km) và khóa giao dịch chống đặt trùng (`HTTP 409 Conflict`).
2. **Tuyển vãng lai 2 chiều & Tự động chia tiền:** Cho phép Đội trưởng (Host) bật tuyển thêm người chơi vãng lai qua App hoặc nhờ Lễ tân gán khách lẻ tại quầy. Hệ thống tự động chia đều tiền sân theo đầu người và khấu trừ trực tiếp vào hóa đơn của Host.
3. **Vé điện tử ngoại tuyến (Offline QR Pass):** Lưu trữ vé vào cơ sở dữ liệu cục bộ **SQLite (`sqflite`)** và tự sinh mã QR động có chữ ký bảo mật (`SHA-256 Checksum`), giúp người chơi mở vé check-in ngay cả khi mất hoàn toàn kết nối mạng 4G/Wi-Fi.

---

## 📚 Ý Nghĩa Các Tài Liệu Trong Thư Mục [`documents/`](./documents/)

Toàn bộ tài liệu đặc tả yêu cầu sản phẩm (PRD 2.0) và hướng dẫn kỹ thuật của nhóm được đặt tại thư mục [`documents/`](./documents/):

| STT | Tên File / Thư Mục | Ý Nghĩa & Nội Dung Chính |
| :-: | :--- | :--- |
| 0 | [**`00_PROJECT_CHARTER.md`**](./documents/00_PROJECT_CHARTER.md) | Tôn chỉ dự án, mục tiêu đầu ra môn học (CLOs), lộ trình W2–W9 và ma trận phân công RACI. |
| 1 | [**`01_PRODUCT_OVERVIEW.md`**](./documents/01_PRODUCT_OVERVIEW.md) | Bối cảnh sản phẩm, lợi thế cạnh tranh (UVP), Context Diagram 8 Entities và chân dung người dùng. |
| 2 | [**`02_SYSTEM_ARCHITECTURE.md`**](./documents/02_SYSTEM_ARCHITECTURE.md) | Kiến trúc tổng thể hệ thống giữa Mobile Flutter, Backend .NET 8, Supabase và các dịch vụ Cloud. |
| 3 | [**`03_FUNCTIONAL_REQUIREMENTS.md`**](./documents/03_FUNCTIONAL_REQUIREMENTS.md) | Đặc tả chi tiết 14 tính năng (F01–F14) kèm User Story và tiêu chí nghiệm thu Gherkin. |
| 4 | [**`04_NON_FUNCTIONAL_REQUIREMENTS.md`**](./documents/04_NON_FUNCTIONAL_REQUIREMENTS.md) | Tiêu chuẩn hiệu năng phản hồi API, bảo mật JWT/BCrypt/OTP và cơ chế hoạt động Offline-first. |
| 5 | [**`05_BUSINESS_RULES.md`**](./documents/05_BUSINESS_RULES.md) | Quy tắc nghiệp vụ: đặt tối đa 3 slot liên tiếp, chia tiền vãng lai, giữ tiền Escrow, phạt hủy bậc thang. |
| 6 | [**`06_DATA_SPECIFICATION_ERD.md`**](./documents/06_DATA_SPECIFICATION_ERD.md) | Sơ đồ ERD 3 cấp độ (Conceptual, Logical, Physical), thiết kế bảng SQLite và script SQL DDL. |
| 7 | [**`07_USECASES_WORKFLOWS.md`**](./documents/07_USECASES_WORKFLOWS.md) | Sơ đồ Use Case tổng quát và 4 Sequence Diagrams mô tả luồng tương tác cốt lõi. |
| 8 | [**`08_API_CONTRACT.md`**](./documents/08_API_CONTRACT.md) | Hợp đồng giao tiếp RESTful API JSON chuẩn hóa (Endpoints, Request/Response Schema, Status Codes). |
| 9 | [**`09_REQUIREMENTS_TRACEABILITY_RISKS.md`**](./documents/09_REQUIREMENTS_TRACEABILITY_RISKS.md) | Ma trận truy vết yêu cầu (RTM) và kế hoạch phòng ngừa rủi ro kỹ thuật khi demo. |
| 10 | [**`10_TEAM_TASK_ASSIGNMENT_GUIDE.md`**](./documents/10_TEAM_TASK_ASSIGNMENT_GUIDE.md) | Phân bổ công việc cho 5 thành viên (Vertical Slice: cả FE + BE) và hướng dẫn code Mock độc lập. |
| 11 | [**`CODEBASE_STRUCTURE.md`**](./documents/CODEBASE_STRUCTURE.md) | **Sơ đồ cây thư mục Codebase:** Giải thích vai trò của từng folder và file trong `backend/` và `frontend/`. |
| 📦 | [**`legacy/`**](./documents/legacy/) | Thư mục lưu trữ 5 file tài liệu nháp ban đầu của nhóm để đối chiếu lịch sử. |

---

## 🚀 Hướng Dẫn Khởi Chạy Nhanh (Quick Start)

### Cách 1: Khởi chạy tự động bằng `dev.bat` (Windows)
Chạy trực tiếp file [`dev.bat`](./dev.bat) ở thư mục gốc và chọn phím `[1]` để tự động bật cả Backend (cổng `5000`) và Frontend Flutter Web trên trình duyệt Edge (cổng `3000`).

### Cách 2: Khởi chạy thủ công từng phần

#### 1. Backend API (`.NET 8` – 3-Layer Architecture)
Backend đọc biến môi trường từ file `.env` (tham khảo `.env.example`). Nếu chưa cấu hình PostgreSQL/Supabase, hệ thống sẽ **tự động tạo SQLite local (`sportspot_dev.db`)** kèm dữ liệu sân mẫu:

```bash
cd backend
dotnet build SportSpot.sln
dotnet run --project SportSpot.API --urls http://localhost:5000
```
* **Swagger UI:** Mở trình duyệt tại `http://localhost:5000`.
* **Chế độ Bypass Auth khi Dev:** Truyền header `X-Mock-User-Id: 1` trong request để giả lập người dùng đã đăng nhập.

#### 2. Ứng dụng Frontend (`Flutter 3.x`)
```bash
cd frontend
flutter pub get
flutter run
```
* *(Lưu ý: Trên máy ảo Android Emulator, địa chỉ gọi về Backend localhost trên máy tính là `http://10.0.2.2:5000`).*
