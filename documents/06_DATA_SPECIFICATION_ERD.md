# 🗄️ Đặc Tả Dữ Liệu & Thiết Kế ERD (Data Specification & ERD)

Tài liệu cung cấp thiết kế cơ sở dữ liệu hoàn chỉnh ở cả 3 cấp độ: **Conceptual ERD**, **Logical ERD** và **Physical ERD**, kèm Từ điển dữ liệu (Data Dictionary) và script SQL DDL.

---

## 1. Mô hình ERD 3 Cấp Độ (3-Level Data Models)

### 1.1. Conceptual ERD (Mức Quan niệm - Tổng thể Nghiệp vụ)
```mermaid
erDiagram
    USER ||--o{ BOOKING : "places (đặt sân)"
    USER ||--o{ OPEN_MATCH : "hosts (tạo kèo)"
    USER }|--|{ OPEN_MATCH : "joins (tham gia kèo)"
    USER ||--o{ VENUE : "owns (sở hữu)"
    USER ||--o{ VENUE : "approves (duyệt sân)"
    
    SPORT ||--|{ VENUE : "categorizes (phân loại)"
    VENUE ||--|{ SUB_VENUE : "contains (gồm sân con)"
    VENUE ||--o{ SERVICE : "provides (đồ thuê/bán)"
    
    SUB_VENUE ||--o{ BOOKING : "scheduled for"
    BOOKING }|--|{ TIME_SLOT : "reserves (chọn khung giờ)"
    BOOKING }|--|{ SERVICE : "includes (kèm phụ kiện)"
    BOOKING ||--o| OPEN_MATCH : "recruits for (tuyển vãng lai)"
    BOOKING ||--o{ TRANSACTION : "paid via (thanh toán)"

    USER {
        string full_name
        string phone_number
        string role
    }

    SPORT {
        string sport_name
    }

    VENUE {
        string venue_name
        string address
        string district
    }

    SUB_VENUE {
        string court_name
    }

    TIME_SLOT {
        string start_time
        string end_time
    }

    SERVICE {
        string item_name
        string type
        int price
    }

    BOOKING {
        string booking_code
        date play_date
        int total_price
        string status
    }

    OPEN_MATCH {
        int total_players
        int cost_per_person
        string status
    }

    TRANSACTION {
        string transaction_code
        int amount
        string status
    }
```

---

### 1.2. Physical ERD (Mức Vật lý - Supabase PostgreSQL)
```mermaid
erDiagram
    Sports ||--o{ Venues : "sport_id"
    Users ||--o{ Venues : "owner_id"
    Users ||--o{ Venues : "approved_by"
    Venues ||--o{ SubVenues : "venue_id"
    Venues ||--o{ Services : "venue_id"
    
    Users ||--o{ Bookings : "user_id"
    SubVenues ||--o{ Bookings : "sub_venue_id"
    
    Bookings ||--o{ BookingDetails : "booking_id"
    TimeSlots ||--o{ BookingDetails : "slot_id"
    
    Bookings ||--o{ BookingServices : "booking_id"
    Services ||--o{ BookingServices : "service_id"
    
    Bookings ||--o| OpenMatches : "booking_id"
    Users ||--o{ OpenMatches : "host_user_id"
    
    OpenMatches ||--o{ MatchMembers : "match_id"
    Users ||--o{ MatchMembers : "user_id"
    
    Bookings ||--o{ Transactions : "booking_id"
    Users ||--o{ Transactions : "user_id"

    Users {
        int id PK "SERIAL"
        varchar full_name "VARCHAR(100) NOT NULL"
        varchar phone_number UK "VARCHAR(20) NOT NULL UNIQUE"
        varchar email UK "VARCHAR(150) UNIQUE"
        varchar password_hash "VARCHAR(255) NOT NULL"
        varchar role "VARCHAR(30) DEFAULT 'Player'"
        boolean is_find_match_enabled "BOOLEAN DEFAULT FALSE"
        varchar favorite_sports "VARCHAR(255)"
        timestamptz created_at "TIMESTAMPTZ DEFAULT NOW()"
    }

    Sports {
        int id PK "SERIAL"
        varchar name UK "VARCHAR(50) NOT NULL UNIQUE"
        varchar icon_url "VARCHAR(255)"
    }

    Venues {
        int id PK "SERIAL"
        int sport_id FK "INT REFERENCES Sports(id)"
        int owner_id FK "INT REFERENCES Users(id)"
        string name "VARCHAR(150) NOT NULL"
        string address "VARCHAR(255) NOT NULL"
        string district "VARCHAR(100) NOT NULL"
        decimal latitude "DECIMAL(10,7) NOT NULL"
        decimal longitude "DECIMAL(10,7) NOT NULL"
        string hotline "VARCHAR(20) NOT NULL"
        int base_price "INT NOT NULL"
        int peak_price "INT NOT NULL"
        decimal rating "DECIMAL(2,1) DEFAULT 5.0"
        varchar status "VARCHAR(20) DEFAULT 'Approved'"
        int approved_by FK "INT REFERENCES Users(id)"
        boolean is_active "BOOLEAN DEFAULT TRUE"
    }

    SubVenues {
        int id PK "SERIAL"
        int venue_id FK "INT REFERENCES Venues(id)"
        varchar name "VARCHAR(50) NOT NULL"
    }

    Services {
        int id PK "SERIAL"
        int venue_id FK "INT REFERENCES Venues(id)"
        varchar name "VARCHAR(100) NOT NULL"
        varchar type "VARCHAR(20) NOT NULL"
        int price "INT NOT NULL"
        int stock_quantity "INT DEFAULT 0"
    }

    TimeSlots {
        int id PK "SERIAL"
        varchar start_time "VARCHAR(10) NOT NULL"
        varchar end_time "VARCHAR(10) NOT NULL"
        boolean is_peak "BOOLEAN DEFAULT FALSE"
    }

    Bookings {
        int id PK "SERIAL"
        varchar booking_code UK "VARCHAR(20) NOT NULL UNIQUE"
        int user_id FK "INT REFERENCES Users(id)"
        int sub_venue_id FK "INT REFERENCES SubVenues(id)"
        date play_date "DATE NOT NULL"
        int court_price "INT NOT NULL"
        int services_price "INT DEFAULT 0"
        int total_price "INT NOT NULL"
        int deposit_amount "INT NOT NULL"
        int remaining_balance "INT NOT NULL"
        varchar booking_type "VARCHAR(30) DEFAULT 'Standard'"
        varchar status "VARCHAR(30) DEFAULT 'Upcoming'"
        timestamptz created_at "TIMESTAMPTZ DEFAULT NOW()"
    }

    BookingDetails {
        int id PK "SERIAL"
        int booking_id FK "INT REFERENCES Bookings(id)"
        int slot_id FK "INT REFERENCES TimeSlots(id)"
        int price "INT NOT NULL"
    }

    BookingServices {
        int id PK "SERIAL"
        int booking_id FK "INT REFERENCES Bookings(id)"
        int service_id FK "INT REFERENCES Services(id)"
        int quantity "INT NOT NULL"
        int price "INT NOT NULL"
    }

    OpenMatches {
        int id PK "SERIAL"
        int booking_id FK "INT UNIQUE REFERENCES Bookings(id)"
        int host_user_id FK "INT REFERENCES Users(id)"
        int total_expected_players "INT NOT NULL"
        int needed_players "INT NOT NULL"
        int current_joined_players "INT DEFAULT 0"
        int cost_per_person "INT NOT NULL"
        varchar status "VARCHAR(20) DEFAULT 'Open'"
        timestamptz created_at "TIMESTAMPTZ DEFAULT NOW()"
    }

    MatchMembers {
        int id PK "SERIAL"
        int match_id FK "INT REFERENCES OpenMatches(id)"
        int user_id FK "INT REFERENCES Users(id)"
        varchar member_type "VARCHAR(20) DEFAULT 'AppUser'"
        int paid_amount "INT NOT NULL"
        varchar payment_status "VARCHAR(20) DEFAULT 'Paid'"
        varchar ticket_qr_payload "VARCHAR(255)"
        timestamptz joined_at "TIMESTAMPTZ DEFAULT NOW()"
    }

    Transactions {
        int id PK "SERIAL"
        int booking_id FK "INT REFERENCES Bookings(id)"
        int user_id FK "INT REFERENCES Users(id)"
        int amount "INT NOT NULL"
        varchar payment_gateway "VARCHAR(30) NOT NULL"
        varchar transaction_code UK "VARCHAR(100) NOT NULL UNIQUE"
        varchar status "VARCHAR(30) DEFAULT 'Holding'"
        timestamptz created_at "TIMESTAMPTZ DEFAULT NOW()"
    }
```

---

## 2. Thiết kế Local Database (SQLite trên Flutter Client)

```mermaid
erDiagram
    user_session {
        int user_id PK "INTEGER PRIMARY KEY"
        text full_name "TEXT NOT NULL"
        text phone_number "TEXT NOT NULL"
        text email "TEXT"
        text role "TEXT NOT NULL"
        text access_token "TEXT NOT NULL"
        text logged_in_at "TEXT NOT NULL"
    }

    app_settings {
        text setting_key PK "TEXT PRIMARY KEY"
        text setting_value "TEXT NOT NULL"
        text updated_at "TEXT NOT NULL"
    }

    offline_bookings {
        text booking_code PK "TEXT PRIMARY KEY"
        int venue_id "INTEGER NOT NULL"
        text venue_name "TEXT NOT NULL"
        text sub_venue_name "TEXT NOT NULL"
        text address "TEXT NOT NULL"
        text play_date "TEXT NOT NULL"
        text time_slots "TEXT NOT NULL"
        text user_role_in_match "TEXT NOT NULL"
        int total_price "INTEGER NOT NULL"
        int deposit_amount "INTEGER NOT NULL"
        text status "TEXT NOT NULL"
        text qr_payload "TEXT NOT NULL"
        int notification_id "INTEGER NOT NULL"
        text created_at "TEXT NOT NULL"
    }
```

---

## 3. Script SQL DDL Tạo Bảng Hoàn Chỉnh (PostgreSQL - Supabase)

```sql
-- 1. Bảng Users
CREATE TABLE IF NOT EXISTS "Users" (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'Player',
    is_find_match_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    favorite_sports VARCHAR(255) DEFAULT 'Cầu lông,Bóng đá mini',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Bảng Sports
CREATE TABLE IF NOT EXISTS "Sports" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    icon_url VARCHAR(255)
);

-- 3. Bảng Venues
CREATE TABLE IF NOT EXISTS "Venues" (
    id SERIAL PRIMARY KEY,
    sport_id INT NOT NULL REFERENCES "Sports"(id) ON DELETE CASCADE,
    owner_id INT REFERENCES "Users"(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    district VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    description TEXT,
    hotline VARCHAR(20) NOT NULL,
    image_url VARCHAR(255),
    base_price INT NOT NULL,
    peak_price INT NOT NULL,
    rating DECIMAL(2,1) NOT NULL DEFAULT 5.0,
    status VARCHAR(20) NOT NULL DEFAULT 'Approved',
    approved_by INT REFERENCES "Users"(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Bảng SubVenues
CREATE TABLE IF NOT EXISTS "SubVenues" (
    id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL REFERENCES "Venues"(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL
);

-- 5. Bảng Services
CREATE TABLE IF NOT EXISTS "Services" (
    id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL REFERENCES "Venues"(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    price INT NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

-- 6. Bảng TimeSlots
CREATE TABLE IF NOT EXISTS "TimeSlots" (
    id SERIAL PRIMARY KEY,
    start_time VARCHAR(10) NOT NULL,
    end_time VARCHAR(10) NOT NULL,
    is_peak BOOLEAN NOT NULL DEFAULT FALSE
);

-- 7. Bảng Bookings
CREATE TABLE IF NOT EXISTS "Bookings" (
    id SERIAL PRIMARY KEY,
    booking_code VARCHAR(20) NOT NULL UNIQUE,
    user_id INT NOT NULL REFERENCES "Users"(id) ON DELETE CASCADE,
    sub_venue_id INT NOT NULL REFERENCES "SubVenues"(id) ON DELETE CASCADE,
    play_date DATE NOT NULL,
    court_price INT NOT NULL,
    services_price INT NOT NULL DEFAULT 0,
    total_price INT NOT NULL,
    deposit_amount INT NOT NULL,
    remaining_balance INT NOT NULL,
    booking_type VARCHAR(30) NOT NULL DEFAULT 'Standard',
    status VARCHAR(30) NOT NULL DEFAULT 'Upcoming',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Bảng BookingDetails
CREATE TABLE IF NOT EXISTS "BookingDetails" (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES "Bookings"(id) ON DELETE CASCADE,
    slot_id INT NOT NULL REFERENCES "TimeSlots"(id) ON DELETE RESTRICT,
    price INT NOT NULL,
    CONSTRAINT UQ_BookingSlot UNIQUE (booking_id, slot_id)
);

-- 9. Bảng BookingServices
CREATE TABLE IF NOT EXISTS "BookingServices" (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES "Bookings"(id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES "Services"(id) ON DELETE RESTRICT,
    quantity INT NOT NULL,
    price INT NOT NULL
);

-- 10. Bảng OpenMatches
CREATE TABLE IF NOT EXISTS "OpenMatches" (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE REFERENCES "Bookings"(id) ON DELETE CASCADE,
    host_user_id INT NOT NULL REFERENCES "Users"(id) ON DELETE CASCADE,
    total_expected_players INT NOT NULL,
    needed_players INT NOT NULL,
    current_joined_players INT NOT NULL DEFAULT 0,
    cost_per_person INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Bảng MatchMembers
CREATE TABLE IF NOT EXISTS "MatchMembers" (
    id SERIAL PRIMARY KEY,
    match_id INT NOT NULL REFERENCES "OpenMatches"(id) ON DELETE CASCADE,
    user_id INT REFERENCES "Users"(id) ON DELETE SET NULL,
    member_type VARCHAR(20) NOT NULL DEFAULT 'AppUser',
    paid_amount INT NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Paid',
    ticket_qr_payload VARCHAR(255),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Bảng Transactions
CREATE TABLE IF NOT EXISTS "Transactions" (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES "Bookings"(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES "Users"(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    payment_gateway VARCHAR(30) NOT NULL,
    transaction_code VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'Holding',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 4. Dữ Liệu Mẫu Khởi Tạo (Seed Data Script)

```sql
-- 1. Sports
INSERT INTO "Sports" (name, icon_url) VALUES 
('Bóng đá mini', 'https://cdn-icons-png.flaticon.com/512/861/861512.png'),
('Cầu lông', 'https://cdn-icons-png.flaticon.com/512/2906/2906478.png'),
('Pickleball', 'https://cdn-icons-png.flaticon.com/512/8144/8144709.png'),
('Bóng rổ', 'https://cdn-icons-png.flaticon.com/512/889/889455.png')
ON CONFLICT (name) DO NOTHING;

-- 2. Venues mẫu tại TP.HCM & Hà Nội
INSERT INTO "Venues" (sport_id, name, address, district, latitude, longitude, description, hotline, base_price, peak_price, rating, status, is_active) VALUES 
(1, 'Sân Bóng Đá Chảo Lửa', 'Số 30 Phan Thúc Duyện, Phường 4', 'Tân Bình', 10.8032, 106.6625, 'Cụm 10 sân cỏ nhân tạo đạt chuẩn FIFA.', '0901234567', 300000, 420000, 4.8, 'Approved', true),
(1, 'Sân Bóng Đá Cỏ Nhân Tạo K334', 'Số 334 Lê Văn Sỹ, Phường 2', 'Tân Bình', 10.7938, 106.6654, 'Cụm sân bóng mini đèn LED chiếu sáng hiện đại.', '0909876543', 280000, 380000, 4.7, 'Approved', true),
(2, 'CLB Cầu Lông Cầu Giấy', 'Số 35 Trần Quý Kiên, Dịch Vọng', 'Cầu Giấy', 21.0368, 105.7905, 'Cụm 6 sân thảm tiêu chuẩn thi đấu.', '0987654321', 90000, 120000, 4.9, 'Approved', true);

-- 3. SubVenues
INSERT INTO "SubVenues" (venue_id, name) VALUES 
(1, 'Sân 5A (Cỏ mới)'),
(1, 'Sân 5B (Cỏ mới)'),
(1, 'Sân 7 (Khán đài)'),
(2, 'Sân 5 số 1'),
(3, 'Sân Cầu Lông số 1 (Thảm Yonex)');

-- 4. Services
INSERT INTO "Services" (venue_id, name, type, price, stock_quantity) VALUES 
(1, 'Thuê bộ áo pitch (10 áo)', 'Rental', 50000, 20),
(1, 'Thùng nước suối Aquafina (24 chai)', 'Sale', 110000, 50),
(1, 'Mua đôi vớ bóng đá chống trượt', 'Sale', 35000, 100),
(3, 'Thuê vợt Yonex Astrox', 'Rental', 30000, 15),
(3, 'Ống cầu lông Hải Yến (12 quả)', 'Sale', 240000, 40);

-- 5. TimeSlots
INSERT INTO "TimeSlots" (start_time, end_time, is_peak) VALUES 
('16:00', '17:00', false),
('17:00', '18:00', true),
('18:00', '19:00', true),
('19:00', '20:00', true),
('20:00', '21:00', true),
('21:00', '22:00', false);
```
