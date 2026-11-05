# Ghép đội bóng và lịch quản lý sân

## Cách sử dụng

### Người chơi

1. Vào **Tìm kèo**, chọn biểu tượng bóng đá **Ghép đội bóng** trên thanh tiêu đề.
2. **Tạo đội**: nhập tên, chọn loại đội 5/7/11 người và trình độ. Người tạo là đội trưởng.
3. Đặt sân bóng theo luồng hiện có. Đơn phải thuộc đội trưởng, sắp diễn ra, chưa mở tuyển người lẻ.
4. Trong màn Ghép đội bóng, chọn **Tìm đối thủ**, chọn đội và đơn sân, nhập lời nhắn.
5. Đội trưởng khác chọn **Gửi lời mời giao hữu**. Hai đội phải cùng loại 5/7/11.
6. Chủ kèo xem **Kèo của tôi**, chọn một đội. Các lời mời còn chờ tự động bị từ chối.
7. Sau khi ghép, hai đội trưởng xem được số điện thoại của nhau. Người ngoài không thấy số điện thoại này.

Kèo hiển thị phần tiền sân đối thủ bằng một nửa tiền sân (làm tròn lên đến đồng). Hai đội thanh toán trực tiếp với nhau; tính năng này **không thu tiền đối thủ qua ví hoặc payOS**. Dịch vụ đi kèm không nằm trong phần tiền sân chia đôi.

Đội trưởng đối thủ có thể rút lời mời trước giờ đá; nếu đã được nhận thì kèo mở lại. Chủ kèo có thể đóng tìm đối thủ mà giữ nguyên đơn sân, sau đó mở lại trên cùng đơn. Hủy đơn sân sẽ đóng kèo và các lời mời đang hoạt động. Một đội không được có hai lịch đối kháng trùng giờ, kể cả khi ở hai sân khác nhau.

### Chủ sân và lễ tân

- Đăng nhập tài khoản **Owner** hoặc **VenueStaff**, chọn tab **Lịch sân**.
- Lịch ngày hiển thị hàng khung giờ, cột sân con; cuộn ngang khi có nhiều sân. Chạm ô trống để tạo lịch, chạm ô đã đặt để xem chi tiết.
- Chọn **7 ngày** để xem danh sách lịch trong bảy ngày kể từ ngày đang chọn.
- **Đặt tại quầy / Bảo trì**: chọn sân con và các giờ liên tiếp. Đơn tại quầy lưu tên, số điện thoại, ghi chú và tiền mặt thực thu; chặn bảo trì cần có lý do.
- **Thu tiền mặt**: ghi nhận từng lần thu, không được vượt số còn thiếu.
- Hủy đơn tại quầy có thu tiền cần xác nhận đã trả lại tiền mặt cho khách. Giao dịch trả tiền được ghi vào lịch sử, không cộng tiền vào ví trên app. Không hủy đơn tại quầy đã bắt đầu.
- **Hoàn tất đơn**: dành cho đơn tại quầy đã thu đủ tiền, sau giờ kết thúc thuê sân.
- **Bảng giá**: chủ sân chỉnh giá thường/cao điểm cho đơn tạo mới. Đơn cũ giữ nguyên giá.
- Chủ sân có thể ngừng/mở nhận khách của sân con. Các đơn đã có vẫn giữ nguyên; dùng chặn giờ bảo trì cho việc bảo trì theo khung giờ.
- Đơn khách đặt qua app được hiển thị trong lịch; việc hủy và hoàn cọc dùng luồng vé hiện có của khách.

### Phân công cụm sân

Đăng nhập **Admin** → **Người dùng** → tài khoản có vai trò **Owner** → biểu tượng **Gán cụm sân quản lý** → chọn cụm sân.

Backend dùng `Users.StaffVenueId` hiện có để phân công chủ sân và lễ tân. Mỗi tài khoản quản lý một cụm sân; Admin truy cập được mọi cụm sân. Tài khoản chưa được phân công sẽ thấy thông báo rõ ràng. Lễ tân được xem/tạo lịch và thu tiền tại cụm sân được gán, nhưng không được đổi giá hoặc bật/tắt cả sân con.

## Database và khởi chạy

- PostgreSQL: migration mới `20261105061119_TeamChallengesAndOwnerSchedule` tạo `Teams`, `TeamChallenges`, `TeamChallengeRequests` và thêm thông tin khách/ghi chú vào `Bookings`. Migration tiếp nhận bảng kỹ năng/cột ngày sinh từng được tạo thủ công mà không xóa chúng khi rollback.
- SQLite: `SqliteModule4Upgrade.Apply` nâng cấp bổ sung khi khởi động, hỗ trợ database dev cũ và chạy lặp lại.
- Lịch tại quầy và bảo trì dùng chung `Bookings` / `BookingDetails` với đặt sân trên app. Unique index sân + ngày + slot là hàng rào chống trùng cho cả ba luồng.
- API khởi động hiện có sẽ áp dụng migration theo cấu hình. Cần khởi động lại backend đang chạy và hot restart Flutter để nạp tính năng mới.

## API mới

Tất cả thao tác ghi yêu cầu JWT. User ID được lấy từ phiên đăng nhập.

| Phương thức | Đường dẫn | Chức năng |
|---|---|---|
| GET | `/api/teams/mine` | Đội do người hiện tại làm đội trưởng |
| POST | `/api/teams` | Tạo đội |
| GET | `/api/teams/challenges` | Kèo đang tìm đối thủ, cho phép khách xem |
| GET | `/api/teams/challenges/mine` | Kèo đã mở hoặc đã gửi lời mời |
| POST | `/api/teams/challenges` | Mở/mở lại kèo từ đơn sân |
| POST | `/api/teams/challenges/{id}/apply` | Gửi lời mời |
| POST | `/api/teams/challenges/{id}/requests/{requestId}/accept` | Nhận đối thủ |
| POST | `/api/teams/challenges/{id}/requests/{requestId}/reject` | Từ chối |
| POST | `/api/teams/challenges/{id}/requests/{requestId}/withdraw` | Rút lời mời |
| POST | `/api/teams/challenges/{id}/cancel` | Đóng tìm đối thủ |
| GET | `/api/owner/venues` | Cụm sân được quản lý |
| GET | `/api/owner/schedule?venueId=1&from=YYYY-MM-DD&to=YYYY-MM-DD` | Lịch trong tối đa 31 ngày |
| POST | `/api/owner/bookings` | Tạo lịch tại quầy/bảo trì |
| POST | `/api/owner/bookings/{id}/collect` | Ghi nhận tiền mặt |
| POST | `/api/owner/bookings/{id}/cancel` | Hủy lịch tại quầy/bỏ chặn |
| POST | `/api/owner/bookings/{id}/complete` | Hoàn tất đơn tại quầy |
| PUT | `/api/owner/venues/{id}/prices` | Cập nhật giá |
| PUT | `/api/owner/venues/{venueId}/owner/{ownerId}` | Admin phân công chủ sân |

Dashboard và bật/tắt sân con hiện có cũng được kiểm tra quyền theo cụm sân. Giao diện chủ sân báo lỗi thật khi API thất bại, không thay bằng dữ liệu mẫu hoặc giả lập thao tác thành công.

## Kiểm thử

```powershell
dotnet run --project backend/SportSpot.TeamOwner.Tests
dotnet run --project backend/SportSpot.Module4.Tests
dotnet run --project backend/SportSpot.Module5.Tests
cd frontend
flutter test --no-pub
```

Bộ kiểm tra mới dùng SQLite riêng trong bộ nhớ; kiểm tra quyền, trùng lịch giữa bảo trì/app/quầy, tiền mặt, trạng thái kèo, quyền riêng tư liên hệ và concurrency. Widget tests kiểm tra gửi/duyệt lời mời, tạo đội, lỗi tải dữ liệu, thu tiền, xác nhận hoàn tiền mặt và lịch 7 ngày.
