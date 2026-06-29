CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name, description) VALUES
('Admin', 'Quản trị toàn bộ hệ thống, tài khoản, dữ liệu và cấu hình'),
('TravelManager', 'Quản lý địa điểm du lịch, nội dung, đánh giá và dữ liệu gợi ý'),
('Traveler', 'Người dùng cuối, tạo lịch trình và nhận gợi ý từ AI');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(500) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    bio VARCHAR(300),
    phone VARCHAR(30),
    avatar_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_users_roles FOREIGN KEY (role_id) REFERENCES roles(id)
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refresh_tokens_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(250) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    province VARCHAR(100) NOT NULL,
    region VARCHAR(20) NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    category VARCHAR(50) NOT NULL,
    estimated_cost DECIMAL(18,2) NOT NULL,
    cost_unit VARCHAR(50) NOT NULL DEFAULT 'VND/person',
    opening_hours VARCHAR(200),
    image_url VARCHAR(500),
    best_time_to_visit VARCHAR(200),
    suitable_weather VARCHAR(300),
    travel_style VARCHAR(200),
    ai_recommendation_note TEXT,
    embedding_text TEXT,
    embedding VECTOR(768),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT ck_destinations_region CHECK (region IN ('North', 'Central', 'South', 'West')),
    CONSTRAINT ck_destinations_cost CHECK (estimated_cost >= 0)
);

CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(200) NOT NULL,
    total_days INT NOT NULL DEFAULT 1,
    budget_input DECIMAL(18,2) NOT NULL,
    preference_input TEXT,
    user_latitude DECIMAL(9,6),
    user_longitude DECIMAL(9,6),
    user_location_name VARCHAR(200),
    current_temperature DECIMAL(4,1),
    current_weather_description VARCHAR(200),
    mongo_ai_log_id VARCHAR(100),
    ai_model_used VARCHAR(100),
    embedding_model_used VARCHAR(100),
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_schedules_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_schedules_total_days CHECK (total_days >= 1),
    CONSTRAINT ck_schedules_budget CHECK (budget_input >= 0)
);

CREATE TABLE schedule_destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL,
    destination_id UUID NOT NULL,
    day_number INT NOT NULL,
    order_in_day INT NOT NULL DEFAULT 1,
    note TEXT,
    estimated_time TIME,
    ai_reason TEXT,
    weather_fit_note TEXT,
    CONSTRAINT fk_schedule_destinations_schedules FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedule_destinations_destinations FOREIGN KEY (destination_id) REFERENCES destinations(id),
    CONSTRAINT ck_schedule_destinations_day CHECK (day_number >= 1),
    CONSTRAINT ck_schedule_destinations_order CHECK (order_in_day >= 1),
    CONSTRAINT uq_schedule_day_order UNIQUE (schedule_id, day_number, order_in_day)
);

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    destination_id UUID NOT NULL,
    rating INT NOT NULL,
    content TEXT,
    is_approved BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_comments_users FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_comments_destinations FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    CONSTRAINT uq_comments_user_destination UNIQUE (user_id, destination_id),
    CONSTRAINT ck_comments_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    destination_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_favorites_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_favorites_destinations FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    CONSTRAINT uq_user_favorites_user_destination UNIQUE (user_id, destination_id)
);

CREATE TABLE ai_itineraries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NULL,
    title VARCHAR(255),
    request_json JSONB NOT NULL,
    itinerary_json JSONB NOT NULL,
    ai_model VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ai_itineraries_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE trip_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NULL,
    departure_name VARCHAR(255) NOT NULL,
    departure_latitude DOUBLE PRECISION NOT NULL,
    departure_longitude DOUBLE PRECISION NOT NULL,
    total_distance_km DOUBLE PRECISION NOT NULL,
    optimized_hours DOUBLE PRECISION NOT NULL,
    people_count INT NULL,
    budget_per_person DECIMAL(12,2) NULL,
    has_flight_leg BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_trip_routes_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_trip_routes_people_count CHECK (people_count IS NULL OR people_count > 0),
    CONSTRAINT ck_trip_routes_budget CHECK (budget_per_person IS NULL OR budget_per_person >= 0)
);

CREATE TABLE trip_route_legs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_route_id UUID NOT NULL,
    leg_order INT NOT NULL,
    from_name VARCHAR(255) NOT NULL,
    to_name VARCHAR(255) NOT NULL,
    to_region VARCHAR(100) NOT NULL,
    to_latitude DOUBLE PRECISION NOT NULL,
    to_longitude DOUBLE PRECISION NOT NULL,
    distance_km DOUBLE PRECISION NOT NULL,
    duration_hours DOUBLE PRECISION NOT NULL,
    recommended_mode VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL,
    is_google_estimate BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_trip_route_legs_routes FOREIGN KEY (trip_route_id) REFERENCES trip_routes(id) ON DELETE CASCADE,
    CONSTRAINT uq_trip_route_legs_route_order UNIQUE (trip_route_id, leg_order)
);

CREATE TABLE user_travel_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    preferred_styles_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    preferred_transport VARCHAR(80) NOT NULL DEFAULT '',
    average_budget DECIMAL(18,2) NOT NULL DEFAULT 0,
    trip_count INT NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_travel_memories_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_user_travel_memories_average_budget CHECK (average_budget >= 0),
    CONSTRAINT ck_user_travel_memories_trip_count CHECK (trip_count >= 0)
);

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_destinations_region ON destinations(region);
CREATE INDEX idx_destinations_category ON destinations(category);
CREATE INDEX idx_destinations_is_active ON destinations(is_active);
CREATE INDEX idx_schedules_user_id ON schedules(user_id);
CREATE INDEX idx_schedule_destinations_schedule_id ON schedule_destinations(schedule_id);
CREATE INDEX idx_comments_destination_id ON comments(destination_id);
CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_destination_id ON user_favorites(destination_id);
CREATE INDEX idx_ai_itineraries_user_id ON ai_itineraries(user_id);
CREATE INDEX idx_ai_itineraries_created_at ON ai_itineraries(created_at);
CREATE INDEX idx_trip_routes_user_id ON trip_routes(user_id);
CREATE INDEX idx_trip_routes_created_at ON trip_routes(created_at);
CREATE INDEX idx_trip_route_legs_trip_route_id ON trip_route_legs(trip_route_id);
CREATE INDEX idx_user_travel_memories_user_id ON user_travel_memories(user_id);

CREATE OR REPLACE VIEW vw_destination_ratings AS
SELECT d.id AS destination_id, d.name AS destination_name, d.province, d.region, d.category,
       COUNT(c.id) AS total_reviews, ROUND(AVG(c.rating)::numeric, 2) AS average_rating
FROM destinations d
LEFT JOIN comments c ON c.destination_id = d.id AND c.is_approved = TRUE
WHERE d.is_active = TRUE
GROUP BY d.id, d.name, d.province, d.region, d.category;

CREATE OR REPLACE FUNCTION get_destinations(
    p_region VARCHAR DEFAULT NULL, p_category VARCHAR DEFAULT NULL,
    p_province VARCHAR DEFAULT NULL, p_max_budget DECIMAL DEFAULT NULL)
RETURNS TABLE (
    id UUID, name VARCHAR, slug VARCHAR, description TEXT, province VARCHAR, region VARCHAR,
    category VARCHAR, estimated_cost DECIMAL, cost_unit VARCHAR, image_url VARCHAR,
    total_reviews BIGINT, average_rating NUMERIC)
AS $$
BEGIN
    RETURN QUERY
    SELECT d.id, d.name, d.slug, d.description, d.province, d.region, d.category,
           d.estimated_cost, d.cost_unit, d.image_url,
           COALESCE(r.total_reviews, 0), COALESCE(r.average_rating, 0)
    FROM destinations d
    LEFT JOIN vw_destination_ratings r ON r.destination_id = d.id
    WHERE d.is_active = TRUE
      AND (p_region IS NULL OR d.region = p_region)
      AND (p_category IS NULL OR d.category = p_category)
      AND (p_province IS NULL OR d.province = p_province)
      AND (p_max_budget IS NULL OR d.estimated_cost <= p_max_budget)
    ORDER BY COALESCE(r.average_rating, 0) DESC, d.estimated_cost ASC, d.name ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_destinations_by_vector(
    p_query_embedding VECTOR(768), p_match_count INT DEFAULT 10, p_max_budget DECIMAL DEFAULT NULL)
RETURNS TABLE (
    id UUID, name VARCHAR, slug VARCHAR, description TEXT, province VARCHAR, region VARCHAR,
    category VARCHAR, estimated_cost DECIMAL, image_url VARCHAR, similarity DOUBLE PRECISION)
AS $$
BEGIN
    RETURN QUERY
    SELECT d.id, d.name, d.slug, d.description, d.province, d.region, d.category,
           d.estimated_cost, d.image_url, 1 - (d.embedding <=> p_query_embedding) AS similarity
    FROM destinations d
    WHERE d.is_active = TRUE AND d.embedding IS NOT NULL
      AND (p_max_budget IS NULL OR d.estimated_cost <= p_max_budget)
    ORDER BY d.embedding <=> p_query_embedding
    LIMIT p_match_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_ai_schedule(
    p_user_id UUID, p_title VARCHAR, p_total_days INT, p_budget_input DECIMAL, p_preference_input TEXT,
    p_user_latitude DECIMAL, p_user_longitude DECIMAL, p_user_location_name VARCHAR,
    p_current_temperature DECIMAL, p_current_weather_description VARCHAR, p_mongo_ai_log_id VARCHAR,
    p_ai_model_used VARCHAR, p_embedding_model_used VARCHAR)
RETURNS UUID AS $$
DECLARE new_schedule_id UUID;
BEGIN
    INSERT INTO schedules (user_id, title, total_days, budget_input, preference_input,
        user_latitude, user_longitude, user_location_name, current_temperature,
        current_weather_description, mongo_ai_log_id, ai_model_used, embedding_model_used)
    VALUES (p_user_id, p_title, p_total_days, p_budget_input, p_preference_input,
        p_user_latitude, p_user_longitude, p_user_location_name, p_current_temperature,
        p_current_weather_description, p_mongo_ai_log_id, p_ai_model_used, p_embedding_model_used)
    RETURNING id INTO new_schedule_id;
    RETURN new_schedule_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_destination_to_schedule(
    p_schedule_id UUID, p_destination_id UUID, p_day_number INT, p_order_in_day INT,
    p_note TEXT DEFAULT NULL, p_estimated_time TIME DEFAULT NULL,
    p_ai_reason TEXT DEFAULT NULL, p_weather_fit_note TEXT DEFAULT NULL)
RETURNS UUID AS $$
DECLARE new_id UUID;
BEGIN
    INSERT INTO schedule_destinations (schedule_id, destination_id, day_number, order_in_day,
        note, estimated_time, ai_reason, weather_fit_note)
    VALUES (p_schedule_id, p_destination_id, p_day_number, p_order_in_day,
        p_note, p_estimated_time, p_ai_reason, p_weather_fit_note)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

INSERT INTO destinations (name, slug, description, province, region, latitude, longitude, category,
    estimated_cost, opening_hours, image_url, best_time_to_visit, suitable_weather, travel_style,
    ai_recommendation_note, embedding_text) VALUES
('Hue', 'hue', 'Co do voi di san cung dinh, lang tam va am thuc dac sac.', 'Thua Thien Hue', 'Central', 16.463700, 107.590900, 'Cultural', 600000, 'Ca ngay', 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=600', 'Thang 1 den thang 8', 'Troi am, it mua', 'Van hoa, lich su', 'Phu hop kham pha di san va am thuc.', 'Hue Thua Thien Hue Central cultural history food'),
('Da Nang', 'da-nang', 'Thanh pho bien nang dong voi My Khe, Son Tra va cau Rong.', 'Da Nang', 'Central', 16.054400, 108.202200, 'Nature', 900000, 'Ca ngay', 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600', 'Thang 3 den thang 8', 'Nang dep, bien em', 'Bien, thanh pho', 'Phu hop nghi bien va kham pha thanh pho.', 'Da Nang Central beach city Son Tra My Khe'),
('Quy Nhon', 'quy-nhon', 'Thanh pho bien yen binh voi Ky Co, Eo Gio va hai san tuoi.', 'Binh Dinh', 'Central', 13.782000, 109.219000, 'Nature', 700000, 'Ca ngay', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600', 'Thang 3 den thang 9', 'Nang, it mua', 'Bien, nghi duong', 'Phu hop du lich bien chi phi vua phai.', 'Quy Nhon Binh Dinh Central beach seafood'),
('Phong Nha', 'phong-nha', 'Vung hang dong noi tieng voi Phong Nha Ke Bang va thien nhien hung vi.', 'Quang Binh', 'Central', 17.610300, 106.309700, 'Nature', 850000, '07:00 - 17:00', 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600', 'Thang 2 den thang 8', 'Kho rao', 'Thien nhien, phieu luu', 'Phu hop kham pha hang dong.', 'Phong Nha Quang Binh Central cave nature adventure'),
('Ha Noi', 'ha-noi', 'Thu do ngan nam van hien voi pho co, ho Guom va am thuc duong pho.', 'Ha Noi', 'North', 21.027800, 105.834200, 'Cultural', 700000, 'Ca ngay', 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?w=600', 'Mua thu', 'Mat me', 'Van hoa, am thuc', 'Phu hop city tour va trai nghiem am thuc.', 'Ha Noi North capital culture street food'),
('Sapa', 'sapa', 'Thi tran nui voi ruong bac thang, ban lang va khi hau mat lanh.', 'Lao Cai', 'North', 22.336400, 103.843800, 'Mountain', 1200000, 'Ca ngay', 'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=600', 'Thang 9 den thang 11', 'Mat lanh', 'Nui, van hoa ban dia', 'Phu hop trekking va nghi duong nui.', 'Sapa Lao Cai North mountain trekking'),
('Ninh Binh', 'ninh-binh', 'Vung dat co Trang An, Tam Coc va canh quan nui da voi.', 'Ninh Binh', 'North', 20.250600, 105.974500, 'Nature', 650000, 'Ca ngay', 'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=600', 'Thang 1 den thang 5', 'Mat, it mua', 'Thien nhien, van hoa', 'Phu hop di thuyen va tham quan chua.', 'Ninh Binh North Trang An Tam Coc nature'),
('Mu Cang Chai', 'mu-cang-chai', 'Diem ngam ruong bac thang dep nhat Tay Bac vao mua lua chin.', 'Yen Bai', 'North', 21.850000, 104.100000, 'Mountain', 900000, 'Ca ngay', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600', 'Thang 9 den thang 10', 'Mat me', 'Nui, nhiep anh', 'Phu hop ngam canh va chup anh.', 'Mu Cang Chai Yen Bai North rice terrace'),
('Phu Quoc', 'phu-quoc', 'Dao ngoc voi bai bien dep, lan bien va hai san phong phu.', 'Kien Giang', 'South', 10.289900, 103.984000, 'Nature', 1500000, 'Ca ngay', 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600', 'Thang 11 den thang 4', 'Nang dep', 'Bien, nghi duong', 'Phu hop nghi duong bien va gia dinh.', 'Phu Quoc Kien Giang South island beach'),
('Con Dao', 'con-dao', 'Quan dao yen tinh voi bien trong, di tich lich su va thien nhien hoang so.', 'Ba Ria - Vung Tau', 'South', 8.686400, 106.608200, 'Nature', 1700000, 'Ca ngay', 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600', 'Thang 3 den thang 9', 'Bien em', 'Bien, lich su', 'Phu hop nghi duong yen tinh.', 'Con Dao South island beach history'),
('Vung Tau', 'vung-tau', 'Thanh pho bien gan Sai Gon, phu hop nghi cuoi tuan.', 'Ba Ria - Vung Tau', 'South', 10.411400, 107.136200, 'Nature', 600000, 'Ca ngay', 'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=600', 'Quanh nam', 'Nang am', 'Bien, cuoi tuan', 'Phu hop di gan va chi phi hop ly.', 'Vung Tau South beach weekend'),
('Mui Ne', 'mui-ne', 'Diem den bien voi doi cat, lang chai va cac mon hai san.', 'Binh Thuan', 'South', 10.933300, 108.283300, 'Nature', 800000, 'Ca ngay', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600', 'Thang 11 den thang 4', 'Nang gio', 'Bien, doi cat', 'Phu hop nghi bien va chup anh doi cat.', 'Mui Ne Binh Thuan South beach sand dunes'),
('Can Tho', 'can-tho', 'Thanh pho mien Tay noi tieng voi cho noi Cai Rang va vuon trai cay.', 'Can Tho', 'West', 10.045200, 105.746900, 'Cultural', 500000, 'Ca ngay', 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600', 'Thang 12 den thang 4', 'Kho rao', 'Song nuoc, am thuc', 'Phu hop trai nghiem cho noi va mien vuon.', 'Can Tho West floating market river culture'),
('Chau Doc', 'chau-doc', 'Thi xa gan bien gioi voi nui Sam, chua Ba va van hoa song nuoc.', 'An Giang', 'West', 10.700000, 105.116700, 'Cultural', 450000, 'Ca ngay', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600', 'Thang 11 den thang 4', 'Kho rao', 'Van hoa, tam linh', 'Phu hop tham quan nui Sam va cho noi.', 'Chau Doc An Giang West culture river'),
('My Tho', 'my-tho', 'Cua ngo mien Tay voi song Tien, cu lao va dac san hu tieu.', 'Tien Giang', 'West', 10.360000, 106.360000, 'Cultural', 400000, 'Ca ngay', 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600', 'Quanh nam', 'Am, it mua', 'Song nuoc, am thuc', 'Phu hop di trong ngay tu TP HCM.', 'My Tho Tien Giang West river food'),
('Ha Tien', 'ha-tien', 'Thanh pho bien Tay Nam voi nui, bien va nhieu thang canh.', 'Kien Giang', 'West', 10.383300, 104.483300, 'Nature', 700000, 'Ca ngay', 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600', 'Thang 11 den thang 4', 'Nang dep', 'Bien, thien nhien', 'Phu hop ket hop bien va van hoa dia phuong.', 'Ha Tien Kien Giang West beach nature'),
('Ben Tre', 'ben-tre', 'Xu dua voi kenh rach, vuon trai cay va trai nghiem miet vuon.', 'Ben Tre', 'West', 10.233300, 106.383300, 'Nature', 450000, 'Ca ngay', 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600', 'Quanh nam', 'Am ap', 'Miet vuon, song nuoc', 'Phu hop trai nghiem nong thon mien Tay.', 'Ben Tre West coconut river garden')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (name, slug, description, province, region, latitude, longitude, category,
    estimated_cost, opening_hours, image_url, best_time_to_visit, suitable_weather, travel_style,
    ai_recommendation_note, embedding_text) VALUES
('Vịnh Hạ Long', 'vinh-ha-long',
 'Di sản thiên nhiên thế giới với hàng nghìn đảo đá vôi hùng vĩ trên biển.',
 'Quảng Ninh', 'North', 20.910100, 107.183900, 'Nature', 1500000, 'Cả ngày',
 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600',
 'Tháng 10 đến tháng 4', 'Trời quang, ít mưa', 'Thiên nhiên, biển đảo',
 'Phù hợp du thuyền và khám phá.', 'Vịnh Hạ Long Quảng Ninh miền Bắc thiên nhiên biển đảo'),
('Phố Cổ Hội An', 'pho-co-hoi-an',
 'Khu phố cổ UNESCO với đèn lồng, ẩm thực và kiến trúc cổ.',
 'Quảng Nam', 'Central', 15.880000, 108.338000, 'Cultural', 500000, '06:00 - 22:00',
 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600',
 'Tháng 3 đến tháng 8', 'Trời ấm, ít mưa', 'Văn hóa, ẩm thực',
 'Phù hợp phố cổ và ẩm thực.', 'Hội An Quảng Nam miền Trung văn hóa phố cổ ẩm thực'),
('Thành phố Đà Lạt', 'thanh-pho-da-lat',
 'Thành phố ngàn hoa với khí hậu mát mẻ quanh năm.',
 'Lâm Đồng', 'South', 11.940400, 108.458300, 'Mountain', 800000, 'Cả ngày',
 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=600',
 'Tháng 10 đến tháng 4', 'Thời tiết mát mẻ', 'Nghỉ dưỡng, thiên nhiên',
 'Phù hợp nghỉ dưỡng mát mẻ.', 'Đà Lạt Lâm Đồng miền Nam núi khí hậu mát mẻ nghỉ dưỡng');
