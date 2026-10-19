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
