# 📜 Quy Tắc Nghiệp Vụ (Business Rules Specification)

Tài liệu quy định chi tiết toàn bộ các quy tắc nghiệp vụ (**Business Rules - BR**) bắt buộc áp dụng trong mã nguồn của nền tảng **SportSpot**.

---

## 1. Nhóm Quy tắc Xác thực & Guest (BR-AUTH)
* `BR-AUTH-01 (Quyền của Guest):` Khách vãng lai (`Guest`) được quyền tra cứu sân, xem chi tiết cụm sân, xem lịch trống và danh sách các kèo mở tuyển người mà không bị bắt buộc đăng nhập.
* `BR-AUTH-02 (Ràng buộc định danh khi đặt/tham gia):` Khi Guest bấm **"Đặt sân"** hoặc **"Tham gia kèo vãng lai"**, hệ thống bắt buộc kích hoạt luồng định danh bằng **Số điện thoại**.
* `BR-AUTH-03 (Quy chuẩn OTP):` Mã OTP gồm 6 chữ số ngẫu nhiên gửi qua SMS/Firebase, có hiệu lực trong 120 giây. Nhập sai quá 3 lần mã OTP sẽ bị hủy và phải yêu cầu gửi lại mã mới.
* `BR-AUTH-04 (Chuyển đổi trạng thái):` Sau khi xác thực OTP thành công, Guest tự động chuyển đổi thành `User`, được cấp Token JWT và lưu thông tin vào bảng `user_session` trong SQLite để tiếp tục hoàn tất thao tác đang dở dang.

---

## 2. Nhóm Quy tắc Đặt lịch & Khung giờ (BR-SLOT)
* `BR-SLOT-01 (Phạm vi đặt ngày):` Cho phép đặt lịch trong phạm vi tối đa 7 ngày tính từ ngày hiện tại ($T$ đến $T+6$). Vô hiệu hóa các slot giờ đã qua trong ngày hiện tại.
* `BR-SLOT-02 (Quy tắc slot liên tục):` Người dùng được chọn tối đa 3 slot (3 tiếng) trong một đơn đặt và các slot **bắt buộc phải liên tiếp nhau** về mặt thời gian.
* `BR-SLOT-03 (Bảng giá theo khung giờ):` Khung giờ thường áp dụng `base_price`; khung giờ cao điểm (17:00 - 22:00) áp dụng `peak_price`.
* `BR-SLOT-04 (Tính linh hoạt sức chứa):` Hệ thống **không áp đặt giới hạn sức chứa cứng (No hard capacity constraints)**. Đội trưởng/Người đại diện hoàn toàn chủ động điều phối số lượng thành viên thực tế tham gia trận đấu.

---

## 3. Nhóm Quy tắc Tuyển Vãng Lai 2 Chiều & Chia Tiền (BR-RECRUIT)
* `BR-RECRUIT-01 (Tham số tuyển vãng lai):` Khi đặt sân, Host có quyền tick chọn checkbox *"Tuyển vãng lai"*. Host nhập 2 tham số:
  * `total_expected_players`: Tổng số người dự kiến tham gia trận đấu.
  * `needed_players`: Số lượng khách vãng lai cần tuyển thêm ($needed\_players < total\_expected\_players$).
* `BR-RECRUIT-02 (Công thức chia tiền tự động):` Hệ thống tự động tính chi phí mà mỗi khách vãng lai phải đóng:
  $$	ext{cost\_per\_person} = 	ext{ROUND}\left(rac{	ext{Tổng tiền sân}}{	ext{total\_expected\_players}}ight)$$
  *Chi phí này được cố định và hiển thị công khai trên bài tuyển, Host không được tự ý sửa để tránh chênh lệch giá.*
* `BR-RECRUIT-03 (Kênh Tuyển Online qua App):`
  * Khách vãng lai bấm "Tham gia" và thanh toán số tiền `cost_per_person` qua Cổng thanh toán.
  * Hệ thống tự động ghi nhận và **giảm trừ trực tiếp vào số tiền sân còn lại mà Host phải thanh toán (`remaining_balance`)**.
  * Khách vãng lai được cấp một **Mã QR vé riêng** hiển thị trong tab "Vé của tôi".
* `BR-RECRUIT-04 (Kênh Tuyển Offline tại Quầy sân):`
  * Hệ thống đẩy cờ báo *"Sân đang tuyển vãng lai"* đến tài khoản Lễ tân của cụm sân đó.
  * Khi có khách lẻ đến quầy hỏi trận, Lễ tân thu tiền mặt $ightarrow$ bấm nút **"Gán vãng lai tại quầy"** để gán trực tiếp khách vào trận.
  * Số tiền lễ tân thu được sẽ được hệ thống ghi nhận và **trừ tiếp vào tổng hóa đơn tiền sân của Host**.
* `BR-RECRUIT-05 (Cơ chế Dừng tuyển linh hoạt):`
  * **Tự động dừng:** Khi số lượng vãng lai tham gia (qua App + qua Quầy) đạt đủ `needed_players`, hệ thống tự động đóng bài tuyển và chuyển trạng thái sang `Full`.
  * **Chủ động dừng:** Host có thể bấm nút **"Dừng tuyển"** trên ứng dụng bất kỳ lúc nào nếu đã tự rủ đủ bạn bè ngoài đời.
* `BR-RECRUIT-06 (Kịch bản không tuyển đủ người):`
  * Trước giờ thi đấu 2 tiếng, nếu số lượng vãng lai chưa đủ, hệ thống gửi thông báo cho Host với 2 lựa chọn:
    * **Lựa chọn 1 (Tiếp tục tìm):** Giữ bài tuyển đến sát giờ thi đấu. Nếu đến giờ vẫn thiếu, trận đấu vẫn diễn ra bình thường, Host và các thành viên tự thỏa thuận bù phần tiền thiếu.
    * **Lựa chọn 2 (Hủy trận):** Host bấm hủy trận. Hệ thống thu một phần tiền cọc của Host (phạt cọc để bồi thường cho Chủ sân và phí sàn); các Khách vãng lai đã đóng tiền được **hoàn trả 100% tiền** về tài khoản.
* `BR-RECRUIT-07 (Chính sách Khách vãng lai hủy tham gia):`
  * **Hủy trước $\ge 4$ tiếng:** Hoàn 100% tiền cho vãng lai. Hệ thống tự động mở lại đúng 1 slot trống trên app để người khác đăng ký thay thế.
  * **Hủy trước từ $2 - 4$ tiếng:** Hoàn 50% tiền cho vãng lai (thu phạt 50% để bồi thường rủi ro cho Host). Hệ thống mở lại slot trống.
  * **Hủy trước $< 1$ tiếng:** Phạt 100% (không hoàn tiền). Toàn bộ số tiền phạt này được hệ thống giữ lại và trừ vào tiền sân để Host không bị thiệt.
* `BR-RECRUIT-08 (Thỏa thuận ngoài đời thực - Trận đấu 7/3):`
  * Hệ thống chỉ làm nhiệm vụ thu hộ và chia đều chi phí giữ sân ban đầu.
  * Sau khi trận đấu kết thúc, việc hai đội tự cá cược vui "đội thua trả 7-3" hay "đội thua bao lốc nước" là thỏa thuận miệng nội bộ giữa các người chơi ngoài đời, tự chuyển khoản hoặc trả tiền mặt cho nhau, hệ thống không can thiệp.

---

## 4. Nhóm Quy tắc Định vị & Chống Spam Thông báo (BR-NOTI)
* `BR-NOTI-01 (Điều kiện kích hoạt thông báo tìm kèo):` Thông báo về một trận đấu mở mới chỉ được bắn đến User khi thỏa mãn đồng thời 3 điều kiện:
  1. User đang bật tùy chọn: `is_find_match_enabled = true` (Chế độ tìm kèo).
  2. Bộ môn thể thao của trận đấu trùng khớp với danh sách môn thể thao yêu thích của User (`favorite_sports`).
  3. Khoảng cách từ User đến cụm sân nằm trong bán kính đã cài đặt (mặc định 5-10km).
* `BR-NOTI-02 (Thời điểm nhắc lịch trận đấu):` Hệ thống kích hoạt thông báo cục bộ trước giờ bắt đầu thi đấu đúng 2 tiếng trên thanh trạng thái điện thoại của tất cả các thành viên trong trận.

---

## 5. Nhóm Quy tắc Dòng tiền & Thanh toán (BR-PAY)
* `BR-PAY-01 (Cơ chế giữ tiền cọc - Escrow):`
  * Tiền cọc đặt sân của Host và tiền tham gia kèo của Vãng lai được thanh toán qua Cổng thanh toán (VNPay / MoMo) và chuyển vào **Tài khoản trung gian của Nền tảng SportSpot (Escrow Account)** ở trạng thái `Holding`.
* `BR-PAY-02 (Tỷ lệ cọc):` Host có thể chọn thanh toán cọc tối thiểu 30% hoặc thanh toán toàn bộ 100% giá trị đơn đặt.
* `BR-PAY-03 (Quyết toán - Payout cho Chủ sân):`
  * Sau khi trận đấu diễn ra và Lễ tân quét mã QR check-in thành công tại quầy (hoặc qua giờ thi đấu 2 tiếng mà không có khiếu nại), hệ thống tự động giải ngân (Payout) cho Chủ sân:
    $$	ext{Tiền quyết toán cho Chủ sân} = 	ext{Tổng tiền đơn đặt} - 	ext{Phí dịch vụ sàn (Platform Fee)}$$
* `BR-PAY-04 (Chính sách Host hủy sân thông thường):`
  * Hủy vé trước giờ bắt đầu thi đấu $\ge 4$ tiếng: Hoàn 100% tiền cọc về tài khoản khách hàng.
  * Hủy vé trước giờ bắt đầu thi đấu $< 4$ tiếng: Không hoàn cọc; tiền cọc được bồi thường cho Chủ sân.
