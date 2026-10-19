# 📚 Bộ Tài Liệu Đặc Tả Yêu Cầu Sản Phẩm (Product Requirements Document - PRD)

**Dự án:** SportSpot – Multi-Sport Venue Booking & Match-Finding Platform  
**Môn học:** PRM393 - Mobile Programming (Học kỳ Fall 2026)  
**Nhóm thực hiện:** Nhóm 2  
**Phiên bản PRD:** 2.0 (Chuẩn hóa toàn diện theo góp ý của Giảng viên)

---

## 🗂️ Danh mục 11 Tài Liệu PRD Hoàn Chỉnh

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
| 11 | [**`10_TEAM_TASK_ASSIGNMENT_GUIDE.md`**](./10_TEAM_TASK_ASSIGNMENT_GUIDE.md) | **Phân chia Task cho 5 thành viên (Vertical Slice: Full FE + BE)**, chiến lược Mock Data độc lập (Zero-blocking) & Hướng dẫn hoàn thành từng bước. | Toàn bộ 5 thành viên |

---

## 🚀 Hướng dẫn nhanh cho các thành viên nhóm
* **Từng thành viên (5 người):** Đọc ngay [10_TEAM_TASK_ASSIGNMENT_GUIDE.md](./10_TEAM_TASK_ASSIGNMENT_GUIDE.md) để nhận task Full-stack (cả Flutter + .NET 8) của mình kèm hướng dẫn code mock độc lập 100%.
* **Mobile Developers:** Đọc kỹ [03_FUNCTIONAL_REQUIREMENTS.md](./03_FUNCTIONAL_REQUIREMENTS.md) để nắm Acceptance Criteria; tra cứu API tại [08_API_CONTRACT.md](./08_API_CONTRACT.md) và cấu trúc SQLite tại [06_DATA_SPECIFICATION_ERD.md](./06_DATA_SPECIFICATION_ERD.md).
* **Backend Developers:** Thực thi DDL script tại [06_DATA_SPECIFICATION_ERD.md](./06_DATA_SPECIFICATION_ERD.md) lên Supabase; áp dụng nghiêm ngặt logic nghiệp vụ tại [05_BUSINESS_RULES.md](./05_BUSINESS_RULES.md).
* **QA / Testers:** Sử dụng ma trận RTM tại [09_REQUIREMENTS_TRACEABILITY_RISKS.md](./09_REQUIREMENTS_TRACEABILITY_RISKS.md) để viết Test Cases kiểm thử toàn diện.
