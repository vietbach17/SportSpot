# 📡 Hợp Đồng API RESTful (API Specification & Contract)

**Tiêu chuẩn dữ liệu:** JSON Response thống nhất, xác thực Bearer Token JWT.  
**Base URL:** `http://10.0.2.2:5000/api` (Android Emulator) hoặc `https://api.sportspot.vn/api` (Production).

---

## 1. Tiêu Chuẩn Phản Hồi Chung (Standard Response Envelope)

### 1.1. Phản hồi Thành công (Success Envelope)
```json
{
  "success": true,
  "message": "Thao tác thành công",
  "data": { ... }
}
```

### 1.2. Phản hồi Thất bại (Error Envelope)
```json
{
  "success": false,
  "message": "Mô tả lỗi tổng quan",
  "errors": ["Lỗi chi tiết 1", "Lỗi chi tiết 2"]
}
```

---

## 2. Chi Tiết Các Endpoints

### 2.1. Phân hệ Xác thực & OTP (`/api/auth`)

#### `POST /api/auth/send-otp`
* **Request Body:**
```json
{
  "phoneNumber": "0901234567"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Mã OTP đã được gửi đến số điện thoại",
  "data": { "expiresInSeconds": 120 }
}
```

#### `POST /api/auth/verify-otp`
* **Request Body:**
```json
{
  "phoneNumber": "0901234567",
  "otpCode": "839201"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "userId": 10,
    "fullName": "Nguyễn Văn Nam",
    "phoneNumber": "0901234567",
    "role": "Player",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 2.2. Phân hệ Cụm Sân & Khung Giờ (`/api/venues`)

#### `GET /api/venues?latitude=10.8032&longitude=106.6625&radiusKm=5&sportId=1`
* **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Sân Bóng Đá Chảo Lửa",
      "address": "Số 30 Phan Thúc Duyện, P.4, Tân Bình",
      "distanceKm": 1.8,
      "minPrice": 300000,
      "rating": 4.8,
      "imageUrl": "https://res.cloudinary.com/sportspot/image/upload/v1/venues/chao-lua.jpg",
      "openMatchesCount": 2
    }
  ]
}
```

#### `GET /api/venues/{venueId}/subvenues/{subVenueId}/slots?date=2026-10-15`
* **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "slotId": 1,
      "startTime": "17:00",
      "endTime": "18:00",
      "price": 420000,
      "isPeak": true,
      "status": "Available"
    },
    {
      "slotId": 2,
      "startTime": "18:00",
      "endTime": "19:00",
      "price": 420000,
      "isPeak": true,
      "status": "Booked"
    }
  ]
}
```

---

### 2.3. Phân hệ Đặt Sân & Thanh Toán (`/api/bookings`)

#### `POST /api/bookings` *(Header: Bearer {token})*
* **Request Body:**
```json
{
  "subVenueId": 1,
  "playDate": "2026-10-15",
  "slotIds": [1, 2],
  "services": [
    { "serviceId": 1, "quantity": 1 }
  ],
  "isRecruitingWalkIn": true,
  "totalExpectedPlayers": 10,
  "neededPlayers": 4,
  "depositPercentage": 50,
  "paymentGateway": "VNPay"
}
```
* **Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "bookingCode": "SP-728194",
    "courtPrice": 840000,
    "servicesPrice": 50000,
    "totalPrice": 890000,
    "depositAmount": 445000,
    "remainingBalance": 445000,
    "paymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
    "qrPayload": "SPORTSPOT|SP-728194|10|Host"
  }
}
```
* **Response Trùng lịch (409 Conflict):**
```json
{
  "success": false,
  "message": "Rất tiếc, khung giờ này vừa có người đặt. Vui lòng chọn giờ khác!"
}
```

---

### 2.4. Phân hệ Kèo Vãng Lai (`/api/matches`)

#### `POST /api/matches/{matchId}/join` *(Header: Bearer {token})*
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Tham gia kèo thành công!",
  "data": {
    "matchId": 12,
    "paidAmount": 60000,
    "ticketQrPayload": "SPORTSPOT|SP-728194|15|JoinedPlayer",
    "remainingBalanceForHost": 385000
  }
}
```

#### `POST /api/matches/{matchId}/assign-walk-in` *(Header: Bearer {staffToken})*
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Đã gán khách vãng lai tại quầy thành công",
  "data": {
    "matchId": 12,
    "remainingNeeded": 1,
    "remainingBalanceForHost": 325000
  }
}
```

#### `POST /api/matches/{matchId}/leave` *(Header: Bearer {token})*
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Hủy tham gia kèo thành công",
  "data": {
    "refundPercentage": 100,
    "refundAmount": 60000,
    "penaltyAmount": 0,
    "slotReopened": true
  }
}
```


---

### 2.5. Phân hệ Thanh Toán Tạm Giữ Escrow (`/api/payments`) [Module 5]

#### `POST /api/payments/create-intent` *(Header: Bearer {token})*
* **Request Body:**
```json
{
  "bookingId": 501,
  "paymentGateway": "VNPay",
  "depositPercent": 50
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "transactionId": 102,
    "paymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
    "escrowStatus": "Holding",
    "amount": 135000,
    "expiresAt": "2026-10-25T18:05:00Z"
  }
}
```

#### `POST /api/payments/webhook-ipn`
* **Request Body:**
```json
{
  "vnp_TxnRef": "TXN-882410",
  "vnp_ResponseCode": "00",
  "vnp_SecureHash": "a1b2c3d4..."
}
```
* **Response (200 OK):**
```json
{
  "RspCode": "00",
  "Message": "Confirm Success"
}
```


#### `POST /api/payments/payos-webhook`
* **Mô tả:** Nhận Webhook IPN thời gian thực từ cổng thanh toán PayOS khi người dùng quét mã VietQR chuyển khoản thành công.
* **Response (200 OK):**
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Xác nhận Webhook PayOS thành công! Tiền cọc đã chuyển sang trạng thái tạm giữ Escrow (Holding)."
}
```

#### `GET /api/payments/status/{bookingId}`
* **Mô tả:** API để ứng dụng Mobile polling kiểm tra trạng thái thanh toán VietQR tự động mỗi 3 giây.
* **Response (200 OK):**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "bookingId": 17,
    "bookingStatus": "Confirmed",
    "transactionStatus": "Completed",
    "isPaid": true
  }
}
```

#### `POST /api/payments/mock-pay/{bookingCode}`
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Thanh toán sandbox tức thì thành công",
  "data": {
    "bookingCode": "SP-882410",
    "escrowStatus": "Holding",
    "qrCodePayload": "SPORTSPOT|SP-882410|1|Host|A1B2C3D4"
  }
}
```

#### `GET /api/payments/history` *(Header: Bearer {token})*
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "walletBalance": 120000,
    "escrowHoldingTotal": 135000,
    "transactions": [
      {
        "id": 1,
        "bookingCode": "SP-882410",
        "venueName": "CLB Cầu Lông Cầu Giấy",
        "amount": 135000,
        "paymentGateway": "VNPay",
        "status": "Holding",
        "createdAt": "2026-10-25T14:30:00Z"
      }
    ]
  }
}
```

---

### 2.6. Phân hệ Vé Điện Tử QR & Hủy Vé Phạt Bậc Thang (`/api/tickets`) [Module 5]

#### `GET /api/tickets/my-tickets` *(Header: Bearer {token})*
* **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "bookingId": 501,
      "bookingCode": "SP-882410",
      "venueName": "CLB Cầu Lông Cầu Giấy",
      "subVenueName": "Sân Số 1 (Thảm Yonex)",
      "sportName": "Cầu lông",
      "playDate": "2026-10-26",
      "timeSlots": ["18:00-19:00", "19:00-20:00"],
      "userRoleInMatch": "Host",
      "totalPrice": 270000,
      "depositAmount": 135000,
      "remainingBalance": 135000,
      "status": "Upcoming",
      "escrowStatus": "Holding",
      "qrPayload": "SPORTSPOT|SP-882410|1|Host|8C2F1A9D",
      "isCheckedIn": false
    }
  ]
}
```

#### `POST /api/tickets/verify-qr` *(Header: Bearer {staffToken})*
* **Request Body:**
```json
{
  "qrPayload": "SPORTSPOT|SP-882410|1|Host|8C2F1A9D"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Xác thực mã QR hợp lệ. Tiền cọc đã giải ngân (Settled) cho chủ sân.",
  "data": {
    "bookingCode": "SP-882410",
    "customerName": "Nguyễn Văn Nam",
    "role": "Host",
    "subVenueName": "Sân Số 1",
    "escrowStatus": "Settled",
    "checkedInAt": "2026-10-26T17:50:00Z"
  }
}
```

#### `POST /api/tickets/{bookingId}/cancel` *(Header: Bearer {token})*
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Hủy vé thành công theo chính sách phạt bậc thang",
  "data": {
    "bookingId": 501,
    "bookingCode": "SP-882410",
    "hoursBeforeMatch": 26.5,
    "refundPercentage": 100,
    "refundAmount": 135000,
    "penaltyAmount": 0,
    "newWalletBalance": 255000,
    "policyApplied": "Bậc 1 (Trước >= 4 giờ): Hoàn 100% cọc"
  }
}
```

---

### 2.7. Phân hệ Khung Giờ Sân Con (`/api/courts`) [Module 3]

#### `GET /api/courts/{subVenueId}/slots?date=YYYY-MM-DD`
* **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "slotId": 13,
      "startTime": "18:00",
      "endTime": "19:00",
      "price": 120000,
      "status": "Available"
    },
    {
      "slotId": 14,
      "startTime": "19:00",
      "endTime": "20:00",
      "price": 120000,
      "status": "Holding"
    }
  ]
}
```
