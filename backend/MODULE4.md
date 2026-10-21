# Module 4 — Ghép kèo & tuyển vãng lai hai chiều

## Phạm vi và kiến trúc

Đối chiếu phần MODULE 4 trong file giao việc, BR-RECRUIT-01–05 và F11:

- Flutter: tab Tìm kèo thực tế, lọc môn/quận, chi tiết/thành viên/avatar, tham gia, QR riêng, dừng tuyển; màn hình quầy dành cho VenueStaff; checkout tối giản và RecruitmentForm tái sử dụng.
- API: Controller chỉ lấy người thao tác từ claims. MatchService xử lý nghiệp vụ; Repository tải dữ liệu; EF Core lưu toàn bộ thành viên, giao dịch và số dư trong một SaveChanges có transaction tự động.
- PostgreSQL: migrations Module4Matchmaking và Module4UniqueMember. SQLite dev: bổ sung cột bằng upgrade idempotent, không xóa database cũ.
- Không giới hạn cứng tổng người chơi. Luôn yêu cầu `totalExpectedPlayers > 1`, `0 < neededPlayers < totalExpectedPlayers`.

## Quyết định nghiệp vụ

`costPerPerson = ROUND(CourtPrice / TotalExpectedPlayers)` bằng decimal, làm tròn .5 lên. Không tính ServicesPrice. Giá do server tính và lưu cố định; không có API sửa giá.

Ví dụ tiền sân 600.000đ, tổng 10 người, tuyển 4: mỗi người đóng 60.000đ. Host cọc 30% = 180.000đ, còn 420.000đ. Một người qua app và một người tại quầy làm số dư còn 300.000đ, giảm chính xác 120.000đ.

Không chặn số dư ở 0: nếu Host đã trả đủ, số âm thể hiện tiền phải trả lại Host. Flutter hiển thị “Host được nhận lại”. Module 5 cần quyết toán khoản credit này; Module 4 không tự chuyển tiền thực.

App ghi thành viên AppUser và giao dịch MockPayment/Holding. Quầy xác nhận đã thu tiền mặt, ghi WalkInAtDesk, giao dịch Cash/Settled và đánh dấu đã check-in cho thành viên đó. UserId của giao dịch tiền mặt là lễ tân thực hiện; thành viên tại quầy không bắt buộc có tài khoản và không được cấp chung một QR định danh giả.

`Open → Full` khi đủ số khách cần tuyển, tính cả hai kênh. Host được chuyển `Open → Stopped`. Kèo đã bắt đầu, booking bị hủy/hoàn thành hoặc đã check-in không nhận thành viên mới. Bảng tin chỉ trả kèo còn tuyển và sắp diễn ra. Thời gian sân tính theo Việt Nam UTC+7.

Revision trên OpenMatch, concurrency tokens trên số dư/trạng thái Booking và unique index (MatchId, UserId) bảo vệ thao tác đồng thời. Xung đột trả 409; client tải lại, không tự gửi lại thao tác thu tiền. Các bản ghi trong lần SaveChanges thất bại đều rollback.

Giữ và gia cố API rời kèo hiện có: hoàn về ví, ghi giao dịch hoàn, hoàn lại số dư tương ứng cho Host, chỉ mở lại trạng thái Full; không mở lại Stopped. Khoảng 1–2 giờ chưa được đặc tả rõ trong tài liệu gốc: giữ cách xử lý đã có là dưới 2 giờ không hoàn; cần nhóm chốt trước khi tích hợp thanh toán thật.

## Chạy và kiểm thử

Từ thư mục gốc:

```powershell
dotnet build backend/SportSpot.sln -c Release
dotnet run --project backend/SportSpot.Module4.Tests -c Release
dotnet run --project backend/SportSpot.API -c Release --urls http://localhost:5000
```

API tự chạy migration PostgreSQL theo cấu hình có sẵn khi khởi động. SQLite local được nâng cấp thêm cột. Không cần reset dữ liệu. Nếu dữ liệu cũ đã có thành viên bị trùng, unique index sẽ yêu cầu xử lý các bản ghi trùng trước khi nâng cấp.

```powershell
cd frontend
flutter test
flutter analyze --no-fatal-infos
flutter run
```

Vào **Tìm kèo → Đặt sân & tuyển → Chọn cụm sân, sân con, ngày và giờ → Tuyển vãng lai**. Checkout này dùng cọc mock 30%, không có phụ kiện; RecruitmentForm nhận courtPrice và trả RecruitmentValue.toJson() để thành viên Module 3 ghép vào checkout đầy đủ có phụ kiện.

API DevBypass chỉ hoạt động trong Development, với `X-Mock-User-Id` của user đã tồn tại. Role lấy từ database, không nhận từ request. Guest xem feed/detail không cần token; các thao tác ghi cần đăng nhập. Tài khoản quầy cần `Users.Role = 'VenueStaff'` và `Users.StaffVenueId` trỏ tới cụm sân được phân công; user không thể tự sửa hai trường này qua profile. Khi đăng nhập bằng tài khoản đó, tab Tìm kèo có biểu tượng quầy lễ tân. Không có user lễ tân được tạo hoặc nâng quyền tự động.

MockMatchRepository dùng dữ liệu trong bộ nhớ, có thể truyền vào MatchFeedScreen(repository: ...) để phát triển UI/test độc lập. Luồng thao tác ghi của giao diện vẫn yêu cầu phiên đăng nhập. Không tự động chuyển sang mock khi API lỗi.

## API

| Method | Endpoint | Quyền / ý nghĩa |
| --- | --- | --- |
| GET | /api/matches?sportId=1&district=Thủ%20Đức | Public: kèo còn tuyển |
| GET | /api/matches/{id} | Public: chi tiết, danh sách thành viên; không lộ QR |
| POST | /api/matches | Host sở hữu booking; mở tuyển cho booking đã có |
| POST | /api/matches/{id}/join | User đăng nhập, MockPayment trong Development |
| POST | /api/matches/{id}/assign-walk-in | VenueStaff đúng cụm sân, đã thu tiền mặt |
| PUT | /api/matches/{id}/stop-recruiting | Host của kèo |
| GET | /api/matches/staff | VenueStaff: ca còn thiếu người thuộc sân được phân công |
| GET | /api/matches/{id}/my-ticket | Chỉ vé riêng của người đang đăng nhập |
| POST | /api/matches/{id}/leave | Rời kèo, hoàn theo mốc thời gian |

Body POST /api/matches:

```json
{"bookingId": 1, "totalExpectedPlayers": 10, "neededPlayers": 4, "skillLevel": "Cơ bản"}
```

Body join: `{"paymentGateway":"MockPayment"}`. assign-walk-in/stop/leave không cần trường userId. Booking POST cũng lấy UserId từ phiên đăng nhập; các trường tuyển có thể gửi ngay trong CreateBookingRequest để tạo booking và kèo cùng một lần lưu.

## Ranh giới tích hợp

Thanh toán thật VNPay/MoMo, callback có xác thực, đồng bộ vé offline và tab Vé của tôi, thông báo/nhắc thiếu người 2 giờ và quyết toán/hoàn tiền thực thuộc các module liên quan. Module 4 cấp QR có chữ ký và endpoint lấy lại vé riêng; chưa thay thế màn hình Vé của tôi của Module 5. Join mock bị chặn ngoài Development và từ chối tên cổng thanh toán thật thay vì giả định đã trả tiền. Bản production cần nối callback thanh toán đã xác minh với cùng cơ chế thêm thành viên có khóa chống trùng.

## Kiểm chứng

Runner backend không cần thêm test framework, dùng SQLite quan hệ trong bộ nhớ; không truy cập database của người dùng. Bao phủ booking→tuyển, giá/rounding/phụ kiện, App + Desk, QR riêng, quyền Host và lễ tân khác sân, duplicate join, rollback khi revision cũ, đủ người, dừng tuyển, rời kèo, prepaid credit và booking đã hủy.

Flutter test bao phủ preview/validation form, guest xem feed→detail, thao tác mock và smoke test ứng dụng. Các kiểm tra PostgreSQL trên database thật, Android/emulator và giao dịch cổng thanh toán chưa được chạy trong bộ kiểm thử này.
