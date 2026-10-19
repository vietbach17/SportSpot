# 🤖 AGENT RULES & INSTRUCTIONS (Quy tắc hoạt động của AI Assistant)

Tài liệu này quy định các nguyên tắc và giới hạn hành vi bắt buộc mà AI Agent phải tuân thủ nghiêm ngặt trong suốt quá trình làm việc trên dự án SportSpot.

---

## 🚫 1. RÀNG BUỘC PHẦN MỀM QUẢN LÝ PHIÊN BẢN (GIT CONSTRAINTS) - CỰC KỲ QUAN TRỌNG

> [!CAUTION]
> **TUYỆT ĐỐI KHÔNG ĐƯỢC TỰ Ý CHẠY CÁC LỆNH `git commit` HOẶC `git push`.**

* **Quy tắc 1 (Không tự Commit/Push):** AI Agent **KHÔNG ĐƯỢC PHÉP** tự ý chạy các lệnh:
  * `git commit ...`
  * `git push ...`
  * `git push origin ...`
  * trừ khi **NGƯỜI DÙNG YÊU CẦU ĐÍCH DANH** trong câu lệnh (Ví dụ: *"hãy commit và push code lên github cho tôi"*).
* **Quy tắc 2 (Chỉ chỉnh sửa & Kiểm thử):** Sau khi hoàn thành việc viết code, sửa lỗi hoặc cập nhật file, Agent chỉ được phép:
  * Kiểm tra biên dịch (`dotnet build`, `flutter analyze`, `flutter test`).
  * Báo cáo các file đã sửa đổi cho người dùng.
  * Hướng dẫn người dùng lệnh git cần thiết hoặc chờ người dùng duyệt trước khi hỏi có muốn commit hay không.

---

## 🛠️ 2. QUY TẮC PHÁT TRIỂN & CẤU TRÚC MÃ NGUỒN

1. **Phân chia thư mục rõ ràng:**
   * Backend: Thư mục `backend/SportSpot.API` (ASP.NET Core Web API .NET 8).
   * Frontend: Thư mục `frontend/` (Flutter Cross-Platform).
2. **Bảo tồn tính toàn vẹn:**
   * Giữ nguyên các tài liệu đặc tả nghiệp vụ ([BR & REQ.md](file:///d:/PRM/BR%20&%20REQ.md), [DB Schema.md](file:///d:/PRM/DB%20Schema.md), [Features.md](file:///d:/PRM/Features.md), [Overview.md](file:///d:/PRM/Overview.md), [TechStack.md](file:///d:/PRM/TechStack.md)).
   * Không xóa hoặc sửa đổi các tính năng đã hoạt động trừ khi có yêu cầu cụ thể.
3. **Môi trường Dev & Chế độ Giả lập (Mock):**
   * Ưu tiên hỗ trợ mock OTP (`123456`) và SQLite dev fallback để bất kỳ ai clone về cũng có thể chạy và test ngay.
