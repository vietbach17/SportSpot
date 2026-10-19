# 📜 Quy tắc nghiệp vụ & Ràng buộc hệ thống (Business Rules & Requirements)

Tài liệu quy định chi tiết toàn bộ logic xử lý (**Business Rules - BR**) và yêu cầu màn hình/chức năng (**Requirements - REQ**) của nền tảng SportSpot.

---

## 1. F01: XÁC THỰC NGƯỜI DÙNG & GUEST WORKFLOW

* **Business Rules (BR):**
  * `BR-AUTH-01 (Quyền của Guest):` Khách vãng lai (`Guest`) được quyền xem danh mục sân, tìm kiếm, xem chi tiết sân, tra cứu lịch trống và xem danh sách các trận đấu đang tuyển vãng lai mà không bị bắt buộc đăng nhập.  
  * `BR-AUTH-02 (Ràng buộc định danh khi đặt/tham gia):` Khi Guest bấm **"Đặt sân"** hoặc **"Tham gia tuyển vãng lai"**, hệ thống bắt buộc kích hoạt luồng định danh bằng **Số điện thoại**.  
  * `BR-AUTH-03 (Xác thực OTP):` Mã OTP gồm 6 chữ số ngẫu nhiên được gửi qua SMS/Firebase, có hiệu lực trong vòng 120 giây. Nhập sai quá 3 lần mã OTP sẽ bị vô hiệu hóa.  
  * `BR-AUTH-04 (Chuyển đổi trạng thái):` Sau khi xác thực OTP thành công, Guest tự động chuyển đổi thành `User`, được cấp Token JWT và lưu thông tin vào bảng `user_session` trong SQLite để tiếp tục hoàn tất thao tác đang dở dang.  
  * `BR-AUTH-05 (Môi trường Thử nghiệm & Mock OTP):` Trong môi trường phát triển và bảo vệ đồ án, hệ thống cho phép kích hoạt chế độ giả lập: các số điện thoại thử nghiệm chấp nhận mã OTP mặc định cố định `123456` để đảm bảo buổi demo diễn ra liên tục, không phụ thuộc vào phí SMS hay rủi ro nghẽn mạng viễn thông.

---

## 2. F04: TÌM KIẾM KHOANH VÙNG BÁN KÍNH & CHỐNG SPAM THÔNG BÁO

* **Business Rules (BR):**
  * `BR-SRCH-01 (Khoanh vùng bán kính):` Hệ thống tính khoảng cách giữa tọa độ GPS hiện tại của thiết bị (hoặc tâm của Quận/Huyện được chọn) và tọa độ địa lý của cụm sân theo công thức Haversine.  
  * `BR-SRCH-02 (Phạm vi quét):` Bán kính tìm kiếm hỗ trợ từ 1km đến tối đa 15km (gợi ý mặc định 5km - 10km).  
  * `BR-NOTI-01 (Điều kiện kích hoạt thông báo tìm kèo):` Thông báo về một trận đấu mở mới chỉ được bắn đến User khi thỏa mãn đồng thời 3 điều kiện:  
    1. User đang bật tùy chọn: `is_find_match_enabled = true` (Chế độ tìm kèo).  
    2. Bộ môn thể thao của trận đấu trùng khớp với danh sách môn thể thao yêu thích của User.  
    3. Khoảng cách từ User đến cụm sân nằm trong bán kính đã cài đặt (mặc định 10km).  
  * `BR-NOTI-02 (Nội dung thông báo):` *"[SportSpot] Kèo {SportName} gần bạn! Sân {VenueName} đang cần tìm thêm {NeededCount} người (Giá chia đều: {CostPerPerson}đ). Bấm để tham gia ngay!"*.  

---

## 3. F06: QUY TẮC ĐẶT LỊCH & KHUNG GIỜ

* **Business Rules (BR):**
  * `BR-SLOT-01 (Phạm vi đặt ngày):` Cho phép đặt lịch trong phạm vi tối đa 7 ngày ($T$ đến $T+6$). Vô hiệu hóa các slot giờ đã qua trong ngày hiện tại.  
  * `BR-SLOT-02 (Quy tắc slot liên tục):` Người dùng được chọn tối đa 3 slot (3 tiếng) trong một đơn đặt và các slot **bắt buộc phải liên tiếp nhau**.  
  * `BR-SLOT-03 (Bảng giá theo khung giờ):` Khung giờ thường áp dụng `base_price`; khung giờ cao điểm (17:00 - 22:00) áp dụng `peak_price`.  
  * `BR-SLOT-04 (Tính linh hoạt sức chứa):` Hệ thống **không áp đặt giới hạn sức chứa cứng (No hard capacity constraints)**. Đội trưởng/Người đại diện hoàn toàn chủ động điều phối số lượng thành viên thực tế tham gia trận đấu.  
  * `BR-SLOT-05 (Cơ chế Slot Holding - Giữ chỗ tạm thời):` Khi người dùng bấm sang màn hình thanh toán, các slot đã chọn chuyển sang trạng thái giữ tạm thời `PendingPayment` trong vòng **10 phút**. Nếu quá 10 phút người dùng không hoàn tất thanh toán, hệ thống tự động giải phóng slot để người khác có thể đặt.

---

## 4. F11: CƠ CHẾ TUYỂN VÃNG LAI 2 CHIỀU & CHIA TIỀN TỰ ĐỘNG

* **Business Rules (BR):**
  * `BR-RECRUIT-01 (Thiết lập tuyển vãng lai):` Khi đặt sân, Host có quyền tick chọn checkbox *"Tuyển thêm vãng lai"*. Host nhập 2 tham số bắt buộc:  
    * `total_expected_players`: Tổng số người dự kiến tham gia trận đấu.  
    * `needed_players`: Số lượng khách vãng lai cần tuyển thêm ($needed\_players < total\_expected\_players$).  
  * `BR-RECRUIT-02 (Công thức chia tiền tự động):` Hệ thống tự động tính chi phí mà mỗi khách vãng lai phải đóng:  
    $$ \text{cost\_per\_person} = \text{ROUND}\left(\frac{\text{Tổng tiền sân}}{\text{total\_expected\_players}}\right) $$  
    *Chi phí này được cố định và hiển thị công khai trên bài tuyển, Host không được tự ý sửa để tránh chênh lệch giá.*  
  * `BR-RECRUIT-03 (Kênh Tuyển Online qua App & Trừ tiền sân):`  
    * Khách vãng lai bấm "Tham gia" và thanh toán số tiền `cost_per_person` qua Cổng thanh toán.  
    * Hệ thống tự động ghi nhận số tiền này và **giảm trừ trực tiếp vào số tiền sân còn lại mà Host phải thanh toán** khi nhận sân.  
    * Khách vãng lai được cấp một **Mã QR vé riêng** hiển thị trong tab "Vé của tôi".  
  * `BR-RECRUIT-04 (Kênh Tuyển Offline tại Quầy sân):`  
    * Hệ thống đẩy cờ báo *"Sân đang tuyển vãng lai"* đến tài khoản Lễ tân của cụm sân đó.  
    * Khi có khách lẻ đến quầy hỏi trận, Lễ tân thu tiền mặt $\rightarrow$ bấm nút **"Gán vãng lai tại quầy"** để gán trực tiếp khách vào trận.  
    * Số tiền lễ tân thu được sẽ được hệ thống ghi nhận và **trừ tiếp vào tổng hóa đơn tiền sân của Host**.  
  * `BR-RECRUIT-05 (Cơ chế Dừng tuyển linh hoạt):`  
    * **Tự động dừng:** Khi số lượng vãng lai tham gia (qua App + qua Quầy) đạt đủ `needed_players`, hệ thống tự động đóng bài tuyển và chuyển trạng thái sang `Full`.  
    * **Chủ động dừng:** Host có thể bấm nút **"Dừng tuyển"** trên ứng dụng bất kỳ lúc nào nếu đã tự rủ đủ bạn bè ngoài đời.  
  * `BR-RECRUIT-06 (Kịch bản không tuyển đủ người):`  
    * Trước giờ thi đấu 2 tiếng, nếu số lượng vãng lai chưa đủ, hệ thống gửi thông báo cho Host với 2 lựa chọn:  
      * **Lựa chọn 1 (Tiếp tục tìm):** Giữ bài tuyển đến sát giờ thi đấu. Nếu đến giờ vẫn thiếu, trận đấu vẫn diễn ra bình thường, Host và các thành viên tự thỏa thuận bù phần tiền thiếu.  
      * **Lựa chọn 2 (Hủy trận):** Host bấm hủy trận. Hệ thống thu một phần tiền cọc của Host (phạt cọc để bồi thường cho Chủ sân và phí sàn); các Khách vãng lai đã đóng tiền được **hoàn trả 100% tiền** vào số dư ví tài khoản `wallet_balance`.  
  * `BR-RECRUIT-07 (Chính sách Khách vãng lai hủy tham gia):`  
    * **Hủy trước $\ge 4$ tiếng:** Hoàn 100% tiền cho vãng lai vào `wallet_balance`. Hệ thống tự động mở lại đúng 1 slot trống trên app để người khác đăng ký thay thế.  
    * **Hủy trước từ $2 - 4$ tiếng:** Hoàn 50% tiền cho vãng lai (thu phạt 50% để bồi thường rủi ro cho Host). Hệ thống mở lại slot trống.  
    * **Hủy trước $< 1$ tiếng:** Phạt 100% (không hoàn tiền). Toàn bộ số tiền phạt này được hệ thống giữ lại và trừ vào tiền sân để Host không bị thiệt.  
  * `BR-RECRUIT-08 (Thỏa thuận ngoài đời thực - Trận đấu 7/3):`  
    * Hệ thống chỉ làm nhiệm vụ thu hộ và chia đều chi phí giữ sân ban đầu.  
    * Sau khi trận đấu kết thúc, việc hai đội tự cá cược vui "đội thua trả 7-3" hay "đội thua bao lốc nước" là thỏa thuận miệng nội bộ giữa các người chơi ngoài đời, tự chuyển khoản hoặc trả tiền mặt cho nhau, hệ thống không can thiệp.  

---

## 5. F12: DỊCH VỤ GIA TĂNG THUÊ & MUA ĐỒ (ADD-ON SERVICES)

* **Business Rules (BR):**
  * `BR-SRV-01 (Danh mục dịch vụ):` Cụm sân phân loại dịch vụ thành 2 nhóm:  
    * **Đồ thuê (Rentals):** Vợt cầu lông, vợt pickleball, giày, áo tập (tính phí theo lượt chơi).  
    * **Đồ mua (Sales):** Ống cầu, bóng, vớ/tất, nước giải khát.  
  * `BR-SRV-02 (Tính tổng chi phí):`  
    $$ \text{Tổng thanh toán} = \text{Tiền sân} + \sum(\text{Giá thuê} \times \text{SL}) + \sum(\text{Giá mua} \times \text{SL}) $$  

---

## 6. F10: DÒNG TIỀN & CỔNG THANH TOÁN (FINANCIAL FLOW & ESCROW)

* **Business Rules (BR):**
  * `BR-PAY-01 (Ai cầm tiền? - Cơ chế giữ tiền cọc):`  
    * Khi khách đặt sân hoặc tham gia kèo, tiền được thanh toán qua **Cổng thanh toán điện tử (VNPay / MoMo / MockPayment)**.  
    * Tiền được chuyển vào **Tài khoản trung gian của Nền tảng SportSpot (Escrow Account)** ở trạng thái `Holding`. Tiền chưa được chuyển ngay cho Chủ sân nhằm bảo vệ quyền lợi của người chơi nếu sân bị hủy hoặc có sự cố.  
  * `BR-PAY-02 (Tỷ lệ cọc):` Host có thể chọn thanh toán cọc tối thiểu 30% hoặc thanh toán toàn bộ 100% giá trị đơn đặt.  
  * `BR-PAY-03 (Quyết toán - Payout cho Chủ sân):`  
    * Sau khi trận đấu diễn ra và Lễ tân quét mã QR check-in thành công tại quầy (hoặc qua giờ thi đấu 2 tiếng mà không có tranh chấp), hệ thống tự động giải ngân (Payout) cho Chủ sân:  
      $$ \text{Tiền quyết toán cho Chủ sân} = \text{Tổng tiền đơn đặt} - \text{Phí dịch vụ nền tảng (Platform Fee)} $$  
  * `BR-PAY-04 (Chính sách hoàn tiền khi Host hủy sân thông thường):`  
    * Hủy vé trước giờ bắt đầu thi đấu $\ge 4$ tiếng: Hoàn 100% tiền cọc về số dư ví `wallet_balance` của tài khoản khách hàng.  
    * Hủy vé trước giờ bắt đầu thi đấu $< 4$ tiếng: Không hoàn cọc; tiền cọc được bồi thường cho Chủ sân để bù đắp chi phí giữ sân.  
  * `BR-PAY-05 (Cổng thanh toán Giả lập - Mock Payment):`  
    * Hệ thống hỗ trợ cổng thanh toán giả lập `MockPayment` để mô phỏng toàn bộ luồng thanh toán cọc/hoàn tiền ngay trên máy ảo mà không yêu cầu cấu hình IPN qua Internet.

---

## 7. F08 & F09: VÉ ĐIỆN TỬ NGOẠI TUYẾN & NHẮC LỊCH (OFFLINE QR & NOTIFICATIONS)

* **Business Rules (BR):**
  * `BR-TKT-01 (Mã QR bảo mật riêng cho từng thành viên):`  
    * Cả Host và từng Khách vãng lai tham gia đều sở hữu một vé điện tử chứa mã QR Code động riêng biệt.  
    * Chuỗi dữ liệu QR chứa mã băm xác thực (SHA-256 Checksum) chống giả mạo:  
      `SPORTSPOT|<booking_code>|<user_id>|<role_in_match>|<checksum>`  
  * `BR-TKT-02 (Hoạt động ngoại tuyến 100% qua SQLite):` Dữ liệu vé và chuỗi sinh QR được lưu vào bảng `offline_bookings` trong SQLite nội bộ máy. Người dùng có thể tắt toàn bộ mạng 4G/Wi-Fi mà vẫn mở vé hiển thị mã QR cho Lễ tân quét đối soát.  
  * `BR-TKT-03 (Quy trình Check-in tại quầy):`  
    * Lễ tân sử dụng camera trên app (`mobile_scanner`) để quét mã QR của từng thành viên khi đến sân.  
    * Hệ thống đối soát mã băm checksum, đổi trạng thái `is_checked_in = true` và lưu thời điểm `checked_in_at`.  
  * `BR-NOTI-03 (Thời điểm nhắc lịch):` Hệ thống kích hoạt thông báo cục bộ trước giờ bắt đầu thi đấu đúng 2 tiếng trên thanh trạng thái điện thoại của tất cả các thành viên trong trận (`flutter_local_notifications`).
