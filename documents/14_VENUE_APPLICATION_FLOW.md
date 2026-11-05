# Đăng ký cụm sân và admin phê duyệt

## Cấu hình

Backend cần `CLOUDINARY_CLOUD_NAME` và `CLOUDINARY_UPLOAD_PRESET` trong môi trường hoặc `.env` được backend nạp. Preset phải cho phép unsigned upload ảnh JPG/PNG/WebP. Có thể cấu hình tương đương bằng `Cloudinary:CloudName` và `Cloudinary:UploadPreset` trong cấu hình ASP.NET. Không đưa API secret vào Flutter. Khi thiếu cấu hình hoặc upload thất bại, app hiển thị lỗi và giữ lại nội dung form để thử lại.

## Thao tác trên app

1. Người chơi đăng nhập mở **Đăng ký sân** ở trang chủ hoặc **Đăng ký và theo dõi hồ sơ sân** ở trang cá nhân. Chủ sân cũng mở được từ biểu tượng thêm cụm sân trên bảng điều khiển.
2. Chọn **Đăng ký sân mới**. Nhập thông tin liên hệ, vị trí, giá, chính sách cọc, tên sân con, giờ hoạt động và chọn 1–8 ảnh đã tải thành công. Ảnh đầu tiên là ảnh đại diện. Ảnh đã tải nhưng chưa dùng có thể chọn lại mà không phải upload lần nữa.
3. Gửi hồ sơ. Backend lưu `Pending`, `IsActive=false`; sân chưa xuất hiện trong danh sách công khai và chưa nhận đặt lịch.
4. Admin vào **Duyệt sân**, mặc định lọc hồ sơ chờ duyệt. Mở **Chi tiết hồ sơ** để xem ảnh (chạm để phóng to), giá, giờ hoạt động, sân con, chính sách và lịch sử duyệt.
5. **Phê duyệt** cần xác nhận. **Từ chối** cần nhập lý do. Chỉ cập nhật giao diện khi API thành công. Trong lúc xử lý, các nút quyết định bị khóa; nếu API trả 409, danh sách tự tải lại trạng thái mới.
6. Sau phê duyệt, sân hoạt động và tài khoản người đăng ký được nâng quyền Owner nếu trước đó là Player/Customer. Người đăng ký làm mới danh sách hồ sơ để đồng bộ vai trò trên app.
7. Hồ sơ bị từ chối hiển thị lý do và nút **Bổ sung và gửi lại**. Form giữ ảnh, giá, chính sách, cấu hình giờ và dịch vụ đã khai báo. Hồ sơ chờ duyệt/đã duyệt không có nút sửa trong luồng này.

## Kiểm thử

```powershell
dotnet run --project backend/SportSpot.TeamOwner.Tests/SportSpot.TeamOwner.Tests.csproj
cd frontend
flutter test test/venue_application_flow_test.dart test/team_owner_features_test.dart
```

Backend kiểm tra phân quyền, chặn đặt sân chờ duyệt, ảnh thuộc người khác, phiên bản hồ sơ cũ, từ chối, gửi lại, nâng quyền và công khai sau duyệt. Widget test kiểm tra form tạo mới/gửi lại, bảo toàn dữ liệu, lỗi tải, lỗi duyệt, bắt buộc lý do và khóa thao tác lặp. Storage trong kiểm thử backend là giả lập; upload Cloudinary thật cần kiểm tra với cấu hình môi trường triển khai.
