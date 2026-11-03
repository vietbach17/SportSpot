# Báo Cáo Triển Khai Tiếp Thu Ý Kiến Đánh Giá Của Giảng Viên (Teacher Feedback) & Mở Rộng Nâng Cao

> **Môn học**: PRM393 - Mobile Programming (Fall 2026)  
> **Dự án**: SportSpot – Nền tảng Đặt Sân Thể Thao, Ký Quỹ Escrow & Ghép Kèo Vãng Lai  
> **Nhánh thực hiện**: `feature/payment-tickets`  
> **Thành viên phụ trách**: **Huy (Fullstack - Luồng Tiền Tệ, Escrow & Vé Điện Tử)**  
> **Ngày cập nhật**: 31/10/2026  

---

## 1. Bối Cảnh & Các Góp Ý Của Giảng Viên

Sau buổi review thực tế, Giảng viên đã đưa ra các nhận xét trọng tâm cần cải tiến trong luồng người dùng:

1. **Vấn đề Khách vãng lai (Guest Join) & Ví hệ thống trên máy**:
   - *Nhận xét*: Khách vãng lai khi lướt tìm trận đấu mở thì không nên bắt buộc phải đăng ký tài khoản qua SĐT (vì một khi đã đăng ký số điện thoại thì đã trở thành "Thành viên/Member" của hệ thống rồi, không còn đúng bản chất "vãng lai").
   - *Yêu cầu*: Cho phép khách vãng lai điền Tên hiển thị + Số điện thoại liên hệ và thanh toán tiền cọc trực tiếp để vào trận ngay mà chưa trở thành member. Nếu trận đấu bị hủy hoặc đổi lịch, tiền cọc sẽ được bảo lưu trong Ví tạm của máy (hoặc làm thủ tục gửi form/mail xin rút về tài khoản ngân hàng), có thể dùng số tiền trong ví này cho các lượt ghép sau mà không cần quét ngân hàng lại.
2. **Vấn đề Thiếu UI Chi tiết đơn đặt sân (Booking Details)**:
   - *Nhận xét*: Sau khi người dùng thanh toán tiền cọc đặt sân thành công, hệ thống còn thiếu màn hình xem thông tin chi tiết của đơn đặt sân (bảng kê tổng phí sân, phụ kiện/dịch vụ đi kèm, số tiền cọc đã trả, số tiền còn lại phải thanh toán tại quầy lễ tân, mã QR check-in).

---

## 2. Chi Tiết Triển Khai Tiếp Thu Ý Kiến & Mở Rộng Chuyên Sâu

### 2.1. Khách Vãng Lai & Ví Tạm Trên Thiết Bị (Local Device Wallet)

#### A. Kiến trúc Tầng Dữ liệu & SQLite (`DatabaseHelper`)
* `getGuestWalletBalance()`: Đọc số dư ví tạm được lưu cục bộ an toàn trên máy (`SharedPreferences` + SQLite, mặc định nạp sẵn 60.000 đ phục vụ demo/thử nghiệm).
* `deductGuestWalletBalance(int amount)`: Trừ số dư khi khách chọn thanh toán cọc bằng ví trên máy.
* `addGuestWalletBalance(int amount)`: Hoàn lại tiền cọc 100% vào ví trên máy khi trận bị hủy hoặc khách vãng lai rời kèo.
* `setGuestWalletBalance(int amount)`: Đồng bộ số dư ví sau khi rút tiền về ngân hàng.
* `recordGuestJoinedMatch(...)`: Lưu định danh vé, mã QR và thông tin khách vãng lai trên thiết bị.
* `upsertOfflineBooking(...)`: Đồng bộ vé khách vãng lai vào bảng SQLite `offline_bookings` để xem được ngoại tuyến và hiển thị trong màn hình "Vé của tôi".

#### B. Giao diện & Trải nghiệm Người dùng (`MatchFeedScreen` & `MatchDetailScreen`)
* **Banner Chế độ Khách vãng lai**: Khi chưa đăng nhập, hiển thị thanh trạng thái Ví tạm trên máy với nút "Chi tiết ví" giải thích rõ cơ chế:
  - Khách vãng lai tham gia không cần tài khoản.
  - Tự động hoàn tiền vào ví trên máy khi sân bị hủy.
  - Hướng dẫn rút về tài khoản ngân hàng hoặc tái sử dụng cho lượt sau.
* **Hộp thoại Tham gia Kèo Vãng Lai (`GuestQuickJoinDialog`)**:
  - Không bắt buộc mở màn hình đăng ký SĐT (`PhoneInputScreen`).
  - Điền Tên hiển thị (VD: "Tuấn Vãng Lai") và Số điện thoại liên hệ (cho Đội trưởng).
  - Lựa chọn nguồn tiền:
    - **Ví tạm trên máy**: Trừ trực tiếp số dư (không cần quét lại).
    - **Cổng thanh toán giả lập**: Thanh toán nhanh.
  - Xuất trình vé QR kèm mã kiểm tra SHA-256 ngay trên máy.
* **Hỗ trợ Rời kèo & Hoàn cọc**: Nếu khách vãng lai bấm "Rời kèo", hệ thống tự động hoàn 100% tiền cọc vào Ví tạm trên máy và cập nhật trạng thái vé.

#### C. Backend Hỗ Trợ Khách Vãng Lai Không Cần Token
* **Endpoint mở**: `POST /api/matches/{id}/guest-join` (Không yêu cầu JWT Bearer Token).
* Ghi nhận `MatchMember` với:
  - `UserId = null`
  - `MemberType = "GuestWalkIn"`
  - `TicketQrPayload = QrChecksumHelper.BuildSignedQrPayload(...)`
  - Giảm `RemainingBalance` của Booking tương ứng, tăng số lượng người tham gia và tự động đóng kèo khi đủ người.

---

### 2.2. Màn Hình Chi Tiết Đơn Đặt Sân (`BookingDetailScreen`)

* **Vị trí file**: `frontend/lib/screens/booking/booking_detail_screen.dart`
* **Các thành phần hiển thị**:
  1. **Header & Huy hiệu trạng thái**: Mã đặt sân (Booking Code, VD: `SP-783921`), Pill trạng thái ("Sắp diễn ra", "Đã thanh toán cọc").
  2. **Thẻ Sân & Lịch thi đấu**: Tên cụm sân, sân phụ, môn thể thao, địa chỉ chi tiết, ngày đấu và các khung giờ đã chọn.
  3. **Thẻ Vé QR Check-in**: Mã QR kèm chuỗi ký danh SHA-256 Checksum chống làm giả/chụp lại, hướng dẫn quét tại quầy lễ tân.
  4. **Bảng Kê Chi Phí Minh Bạch (Invoice Breakdown)**:
     - Tiền thuê sân gốc (`courtPrice`).
     - Chi tiết từng dịch vụ / phụ kiện thuê thêm (vợt, bóng, nước, đèn...) và tổng tiền phụ kiện.
     - Tổng cộng chi phí toàn bộ đơn (`totalPrice`).
     - **Tiền cọc đã thanh toán (Escrow Holding)** (30% hoặc 100%).
     - **Số tiền còn lại cần thanh toán tại quầy lễ tân** (`remainingBalance`).
  5. **Nút điều hướng tiện ích**:
     - "Chia Sẻ Vé Cho Đồng Đội" (sao chép thông điệp thi đấu gửi qua Zalo/Messenger).
     - "Hủy Sân (Hoàn Cọc Escrow)" (áp dụng chính sách hoàn phạt 3 bậc).
     - "Mở Tuyển Ghép Kèo Vãng Lai" (Dẫn sang màn hình tuyển quân).
     - "Về Trang Chủ / Xem Danh Sách Vé".
* **Điểm tích hợp**:
  - Sau khi thanh toán đặt sân tại `BookingCheckoutScreen`, hộp thoại thành công có nút **"Xem Chi Tiết Đơn Đặt Sân"** và nút **"Xem Vé Của Tôi (Mã QR Check-in)"**.
  - Trong màn hình "Vé của tôi" (`MyTicketsScreen`), mỗi vé đang hoạt động có nút **"Xem Bảng Kê Chi Tiết Đơn Đặt Sân"** để xem lại hóa đơn bất cứ lúc nào.

---

### 2.3. Bốn Tính Năng Mở Rộng Nâng Cao Trong Gói 4 (Phụ Trách Bởi Huy)

Để hoàn thiện trọn vẹn luồng tiền tệ và giải quyết triệt để bài toán thầy đặt ra, nhóm đã triển khai thêm 4 tính năng mở rộng chuyên sâu:

1. **Bảng Lịch Sử Ký Quỹ Escrow & Biến Động Ví (`EscrowWalletSheet`)**:
   - Vị trí: `frontend/lib/screens/tickets/escrow_wallet_sheet.dart`
   - Khi bấm vào thẻ `VÍ HOÀN TIỀN` hoặc `ESCROW TẠM GIỮ` trên trang vé, một BottomSheet hiện lên với đầy đủ 2 thẻ số dư lớn và bộ lọc 5 tab (Tất cả, Ký quỹ Holding, Đã giải ngân Settled, Hoàn cọc Refunded, Rút tiền NH).
   - Hiển thị minh bạch từng dòng tiền biến động với icon và badge màu sắc chuẩn Fintech.

2. **Form Yêu Cầu Rút Tiền Ví Về Ngân Hàng (`BankWithdrawalDialog`)**:
   - Vị trí: `frontend/lib/screens/tickets/bank_withdrawal_dialog.dart`
   - **Hiện thực hóa 100% lời Thầy dặn**: Khách hàng có thể rút tiền hoàn cọc từ ví về tài khoản ngân hàng thật (Vietcombank, MB, Techcombank, ACB, VPBank, BIDV, Agribank, TPBank...).
   - Nhập số tài khoản, tên chủ thẻ và số tiền muốn rút (hoặc bấm "Rút tất cả").
   - Hệ thống tự động trừ ví, sinh mã tra soát `WD-xxxxxx`, thêm giao dịch `Processing` vào lịch sử và xuất biên lai điện tử.

3. **Luồng Hủy Sân Tự Động Theo Chính Sách Phạt 3 Bậc (`CancelTicketDialog`)**:
   - Tích hợp trực tiếp trên thẻ vé Active (`MyTicketsScreen`), màn hình vé QR (`TicketQrDetailScreen`) và hóa đơn chi tiết (`BookingDetailScreen`).
   - Tính toán thời gian thực trước giờ thi đấu:
     - Trước $\ge 4h$: Hoàn **100% cọc** về Ví.
     - Từ $2h - 4h$: Hoàn **50% cọc** về Ví, phạt 50% bồi thường chủ sân.
     - Sát giờ $< 2h$: Phạt **100% cọc**, không hoàn tiền.
   - Khi bấm xác nhận: Vé chuyển sang trạng thái `Cancelled`, tiền hoàn tự động cộng vào Ví hoàn tiền.

4. **Tiện Ích Chia Sẻ Vé Cho Đồng Đội (`TicketShareHelper`)**:
   - Vị trí: `frontend/lib/screens/tickets/ticket_share_helper.dart`
   - Giúp người đặt sân sao chép tin nhắn định dạng chuẩn (Mã vé, Cụm sân, Khung giờ, Trạng thái cọc Escrow, Hướng dẫn check-in) để gửi nhanh qua Zalo/Messenger cho bạn bè trong đội.

---

## 3. Kết Quả Kiểm Thử Toàn Diện (All Tests Passed)

| Hạng mục kiểm thử | Công cụ / Lệnh | Kết quả | Ghi chú |
| :--- | :--- | :---: | :--- |
| **Backend Module 4 Tests** | `dotnet run --project backend/SportSpot.Module4.Tests` | **44/44 PASS** | Toàn bộ nghiệp vụ ghép trận, chia tiền sân, dừng tuyển, rời kèo đạt 100% |
| **Backend Module 5 Tests** | `dotnet run --project backend/SportSpot.Module5.Tests` | **19/19 PASS** | Thanh toán Escrow, chữ ký QR SHA-256, 3 bậc hoàn cọc đạt 100% |
| **Frontend Layout & Unit Tests** | `flutter test --no-pub` | **26/26 PASS** | Toàn bộ 7 test suite Flutter (bao gồm Guest Join, Booking Detail, Rút tiền, Chia sẻ vé) đều PASS |
| **Dart Static Analysis** | `dart analyze` | **0 Errors** | Mã nguồn sạch sẽ, tuân thủ tiêu chuẩn Flutter Clean Code |

---

## 4. Tóm Tắt Đáp Ứng Giảng Viên

1. **Khách vãng lai (Guest)**: Hoàn toàn có thể tìm trận, bấm tham gia, điền tên/sđt, thanh toán cọc (bằng Ví tạm trên máy hoặc mock gateway), nhận vé QR lưu trong máy mà KHÔNG bị ép tạo tài khoản.
2. **Ví tạm trên máy & Rút tiền**: Lưu trữ số dư trên thiết bị, tự động nhận tiền hoàn khi sân bị hủy / rời kèo, hỗ trợ form rút tiền về tài khoản ngân hàng với mã tra soát minh bạch.
3. **Màn hình Chi tiết đơn đặt sân**: Đầy đủ bảng kê hóa đơn chi tiết từng dòng, tiền cọc, số dư quầy, và QR check-in.
4. **Ký quỹ Escrow & Vé QR bảo mật**: Lưu trữ offline an toàn bằng SQLite, chống gian lận bằng SHA-256 Checksum, mô phỏng quầy lễ tân quét mã giải ngân Escrow từ `Holding` sang `Settled`.
