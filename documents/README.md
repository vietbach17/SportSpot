# 📚 Bộ Tài Liệu Đặc Tả Yêu Cầu Sản Phẩm (Product Requirements Document - PRD)

**Dự án:** SportSpot – Multi-Sport Venue Booking, Escrow Payment & Match-Finding Platform  
**Môn học:** PRM393 - Mobile Programming (Học kỳ Fall 2026)  
**Nhóm thực hiện:** Nhóm 2  
**Phiên bản PRD:** 2.1 (Chuẩn hóa toàn diện theo góp ý của Giảng viên & Hoàn tất Gói 4 Tiền Tệ / Escrow)  

---

## 🗂️ Danh mục 14 Tài Liệu PRD & Hướng Dẫn Kỹ Thuật

Bộ tài liệu được tổ chức theo tiêu chuẩn kỹ nghệ phần mềm chuyên nghiệp, phục vụ tra cứu cho Product Manager, Mobile Dev, Backend Dev, QA/Tester và Hội đồng chấm thi:

| STT | Tài liệu | Mô tả tóm tắt nội dung | Đối tượng tra cứu |
| :---: | :--- | :--- | :--- |
| 1 | [**`00_PROJECT_CHARTER.md`**](./00_PROJECT_CHARTER.md) | Tôn chỉ dự án, sứ mệnh, mục tiêu CLOs, lộ trình W2-W9, ma trận RACI và tiêu chí nghiệm thu (DoD). | Giảng viên, Leader |
| 2 | [**`01_PRODUCT_OVERVIEW.md`**](./01_PRODUCT_OVERVIEW.md) | Bối cảnh, phân tích đối thủ, UVP, **Context Diagram chuẩn 8 Entities** và User Personas. | Toàn đội, Hội đồng |
| 3 | [**`02_SYSTEM_ARCHITECTURE.md`**](./02_SYSTEM_ARCHITECTURE.md) | Kiến trúc phân tầng, sơ đồ System Architecture toàn diện (Flutter, .NET 8, Supabase, Cloudinary CDN, SQLite). | Mobile & Backend Dev |
| 4 | [**`03_FUNCTIONAL_REQUIREMENTS.md`**](./03_FUNCTIONAL_REQUIREMENTS.md) | Đặc tả 14 tính năng (F01 - F14) kèm User Story, độ ưu tiên MoSCoW và **Tiêu chí nghiệm thu Gherkin (Given-When-Then)**. | Mobile Dev, QA/Tester |
| 5 | [**`04_NON_FUNCTIONAL_REQUIREMENTS.md`**](./04_NON_FUNCTIONAL_REQUIREMENTS.md) | Tiêu chuẩn phi chức năng: Hiệu năng ($\le 500ms$), Bảo mật (JWT, BCrypt, OTP), Offline-first SQLite, Tương thích Android. | Toàn đội, QA/Tester |
| 6 | [**`05_BUSINESS_RULES.md`**](./05_BUSINESS_RULES.md) | Toàn bộ quy tắc nghiệp vụ: Tuyển vãng lai 2 chiều, Tự chia tiền sân, Dừng tuyển, Phạt hủy bậc thang, Giữ tiền cọc Escrow. | Backend Dev, Tester |
| 7 | [**`06_DATA_SPECIFICATION_ERD.md`**](./06_DATA_SPECIFICATION_ERD.md) | Thiết kế ERD 3 cấp độ (**Conceptual, Logical, Physical**), Data Dictionary 15 bảng, DDL SQL và Seed Data. | Database & Backend Dev |
| 8 | [**`07_USECASES_WORKFLOWS.md`**](./07_USECASES_WORKFLOWS.md) | Use Case diagram tổng quan và 4 **Sequence Diagrams** chi tiết cho các luồng cốt lõi. | Toàn đội |
| 9 | [**`08_API_CONTRACT.md`**](./08_API_CONTRACT.md) | Đặc tả hợp đồng API RESTful JSON chuẩn hóa, schema Request/Response và mã lỗi HTTP. | Mobile & Backend Dev |
| 10 | [**`09_REQUIREMENTS_TRACEABILITY_RISKS.md`**](./09_REQUIREMENTS_TRACEABILITY_RISKS.md) | **Ma trận truy vết (RTM)** Feature $\leftrightarrow$ Use Case $\leftrightarrow$ API $\leftrightarrow$ DB; và Kế hoạch quản lý rủi ro dự án. | QA/Tester, Leader |
| 11 | [**`10_TEAM_TASK_ASSIGNMENT_GUIDE.md`**](./10_TEAM_TASK_ASSIGNMENT_GUIDE.md) | **Phân chia 5 Gói Task & 4 Nhánh Git (Duy 100% FE, Hoàng, Khoa, Huy, Bách)**, hướng dẫn độc lập Zero-blocking & nghiệm thu. | Toàn bộ 5 thành viên |
| 12 | [**`CODEBASE_STRUCTURE.md`**](./CODEBASE_STRUCTURE.md) | **Sơ đồ cây thư mục Codebase:** Giải thích vai trò của từng folder và file trong `backend/` (3 Layers) và `frontend/` (Feature-Driven). | Toàn bộ 5 thành viên |
| 13 | [**`11_MODULES_HEALTH_AND_STATUS_REPORT.md`**](./11_MODULES_HEALTH_AND_STATUS_REPORT.md) | **Báo cáo tình trạng sức khỏe 5 Module (100% Sẵn Sàng):** Tiến độ, kết quả test tự động 63/63 BE và 26/26 FE. | Toàn đội, Giảng viên |
| 14 | [**`12_TEACHER_FEEDBACK_IMPLEMENTATION.md`**](./12_TEACHER_FEEDBACK_IMPLEMENTATION.md) | **Báo cáo triển khai phản hồi của Giảng viên & Mở rộng Gói 4:** Khách vãng lai, Ví tạm máy, Hóa đơn chi tiết, Rút tiền NH, Ký quỹ Escrow. | Toàn đội, Giảng viên |

---

## 🚀 Hướng dẫn nhanh cho các thành viên nhóm
* **Phân công theo Gói & Nhánh Git:**
  * **Gói 1 (Duy):** `feature/auth-profile` (100% FE - OTP Login, Session, Profile, Dark/Light Mode).
  * **Gói 2 (Hoàng):** `feature/booking-slots` (Fullstack - Venue Detail $\to$ Court Slots $\to$ Checkout).
  * **Gói 3 (Khoa):** `feature/matchmaking` (Fullstack - Host Game, Join Match, Staff Desk).
  * **Gói 4 (Huy):** `feature/payment-tickets` (Fullstack - Escrow, Vé QR Offline, Rút tiền NH, Hóa đơn chi tiết).
  * **Gói 5 (Bách):** `main` (Leader - Google Maps `url_launcher`, Review Git, Mobile Testing, Demo Script).
* **Kiểm thử tự động:**
  * Chạy test Frontend: `flutter test --no-pub` (26/26 test cases PASS).
  * Chạy test Backend: `dotnet run --project backend/SportSpot.Module4.Tests` (44/44 PASS) và `backend/SportSpot.Module5.Tests` (19/19 PASS).
