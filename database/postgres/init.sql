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
    email VARCHAR(255) UNIQUE,
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
    view_count BIGINT NOT NULL DEFAULT 0,
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

CREATE TABLE auth_verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purpose VARCHAR(40) NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(30),
    full_name VARCHAR(150) NOT NULL,
    password_hash VARCHAR(500) NOT NULL,
    code_hash VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    consumed_at TIMESTAMP,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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

CREATE TABLE transport_hubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(40) NOT NULL,
    province VARCHAR(120) NOT NULL,
    region VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_transport_hubs_type CHECK (type IN ('airport', 'train_station', 'ferry_port', 'bus_station'))
);

CREATE TABLE transport_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    origin_hub_id UUID NOT NULL,
    destination_hub_id UUID NOT NULL,
    transport_type VARCHAR(40) NOT NULL,
    estimated_duration_hours DOUBLE PRECISION NOT NULL,
    estimated_cost_vnd DECIMAL(18,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_transport_routes_origin FOREIGN KEY (origin_hub_id) REFERENCES transport_hubs(id),
    CONSTRAINT fk_transport_routes_destination FOREIGN KEY (destination_hub_id) REFERENCES transport_hubs(id),
    CONSTRAINT ck_transport_routes_type CHECK (transport_type IN ('flight', 'train', 'ferry', 'coach', 'car', 'motorbike')),
    CONSTRAINT ck_transport_routes_duration CHECK (estimated_duration_hours >= 0),
    CONSTRAINT ck_transport_routes_cost CHECK (estimated_cost_vnd >= 0),
    CONSTRAINT uq_transport_route UNIQUE (origin_hub_id, destination_hub_id, transport_type)
);

CREATE TABLE transport_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(120) NOT NULL UNIQUE,
    value VARCHAR(120) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
CREATE INDEX idx_transport_hubs_type_active ON transport_hubs(type, is_active);
CREATE INDEX idx_transport_routes_type_active ON transport_routes(transport_type, is_active);
CREATE INDEX idx_transport_configs_active ON transport_configs(is_active);
CREATE INDEX idx_user_travel_memories_user_id ON user_travel_memories(user_id);

CREATE TABLE content_articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(300) NOT NULL,
    slug VARCHAR(350) NOT NULL UNIQUE,
    summary TEXT,
    content TEXT NOT NULL DEFAULT '',
    article_type VARCHAR(20) NOT NULL DEFAULT 'article',
    category VARCHAR(30) NOT NULL DEFAULT 'destination',
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    author_id UUID NOT NULL,
    thumbnail_url VARCHAR(500),
    destination_id UUID,
    view_count BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    CONSTRAINT fk_content_articles_author FOREIGN KEY (author_id) REFERENCES users(id),
    CONSTRAINT fk_content_articles_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    CONSTRAINT ck_content_articles_type CHECK (article_type IN ('article', 'news')),
    CONSTRAINT ck_content_articles_category CHECK (category IN ('destination', 'experience', 'news')),
    CONSTRAINT ck_content_articles_status CHECK (status IN ('draft', 'pending', 'published'))
);

CREATE TABLE content_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_content_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    link_url VARCHAR(500),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE TABLE gallery_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    destination_id UUID,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_gallery_images_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL
);

CREATE TABLE featured_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    subtitle VARCHAR(300),
    image_url VARCHAR(500),
    link_url VARCHAR(500),
    content_type VARCHAR(50) NOT NULL DEFAULT 'article',
    reference_id UUID,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_content_articles_status ON content_articles(status);
CREATE INDEX idx_content_articles_type ON content_articles(article_type);
CREATE INDEX idx_content_articles_author ON content_articles(author_id);
CREATE INDEX idx_content_articles_created_at ON content_articles(created_at DESC);
CREATE INDEX idx_content_activity_logs_created_at ON content_activity_logs(created_at DESC);
CREATE INDEX idx_destinations_view_count ON destinations(view_count DESC);

INSERT INTO transport_configs (key, value, description) VALUES
('airportSearchRadiusKm', '100', 'Radius for finding an airport near origin/destination.'),
('recommendedFlightDistanceKm', '250', 'Distance threshold where flight becomes the recommended mode when airport hubs exist.'),
('shortFlightDistanceKm', '150', 'Below this distance flight remains selectable but is marked not recommended.'),
('railSearchRadiusKm', '35', 'Radius for finding a railway station near origin/destination.'),
('ferryPortSearchRadiusKm', '70', 'Radius for finding a ferry/speedboat port near origin/destination.');

INSERT INTO transport_hubs (code, name, type, province, region, latitude, longitude, description) VALUES
('tan_son_nhat_airport', 'San bay Tan Son Nhat', 'airport', 'TP.HCM', 'South', 10.8188, 106.6519, 'Airport serving Ho Chi Minh City'),
('noi_bai_airport', 'San bay Noi Bai', 'airport', 'Ha Noi', 'North', 21.2187, 105.8042, 'Airport serving Ha Noi'),
('da_nang_airport', 'San bay Da Nang', 'airport', 'Da Nang', 'Central', 16.0439, 108.1994, 'Airport serving Da Nang'),
('tho_xuan_airport', 'San bay Tho Xuan', 'airport', 'Thanh Hoa', 'Central', 19.9017, 105.4678, 'Airport serving Thanh Hoa'),
('cam_ranh_airport', 'San bay Cam Ranh', 'airport', 'Khanh Hoa', 'Central', 11.9982, 109.2194, 'Airport serving Nha Trang/Khanh Hoa'),
('phu_quoc_airport', 'San bay Phu Quoc', 'airport', 'Kien Giang', 'South', 10.1698, 103.9931, 'Airport serving Phu Quoc'),
('can_tho_airport', 'San bay Can Tho', 'airport', 'Can Tho', 'South', 10.0851, 105.7119, 'Airport serving Can Tho'),
('lien_khuong_airport', 'San bay Lien Khuong', 'airport', 'Lam Dong', 'Central Highlands', 11.7500, 108.3736, 'Airport serving Da Lat/Lam Dong'),
('phu_cat_airport', 'San bay Phu Cat', 'airport', 'Binh Dinh', 'Central', 13.9550, 109.0420, 'Airport serving Binh Dinh'),
('vinh_airport', 'San bay Vinh', 'airport', 'Nghe An', 'Central', 18.7376, 105.6708, 'Airport serving Vinh/Nghe An'),
('cat_bi_airport', 'San bay Cat Bi', 'airport', 'Hai Phong', 'North', 20.8194, 106.7247, 'Airport serving Hai Phong'),
('phu_bai_airport', 'San bay Phu Bai', 'airport', 'Thua Thien Hue', 'Central', 16.4015, 107.7031, 'Airport serving Hue'),
('buon_ma_thuot_airport', 'San bay Buon Ma Thuot', 'airport', 'Dak Lak', 'Central Highlands', 12.6683, 108.1203, 'Airport serving Buon Ma Thuot'),
('pleiku_airport', 'San bay Pleiku', 'airport', 'Gia Lai', 'Central Highlands', 14.0045, 108.0172, 'Airport serving Pleiku'),
('tuy_hoa_airport', 'San bay Tuy Hoa', 'airport', 'Phu Yen', 'Central', 13.0496, 109.3337, 'Airport serving Tuy Hoa'),
('chu_lai_airport', 'San bay Chu Lai', 'airport', 'Quang Nam', 'Central', 15.4033, 108.7060, 'Airport serving Quang Nam/Quang Ngai'),
('dong_hoi_airport', 'San bay Dong Hoi', 'airport', 'Quang Binh', 'Central', 17.5150, 106.5906, 'Airport serving Dong Hoi'),
('rach_gia_airport', 'San bay Rach Gia', 'airport', 'Kien Giang', 'South', 9.9580, 105.1320, 'Airport serving Rach Gia'),
('ca_mau_airport', 'San bay Ca Mau', 'airport', 'Ca Mau', 'South', 9.1777, 105.1778, 'Airport serving Ca Mau'),
('con_dao_airport', 'San bay Con Dao', 'airport', 'Ba Ria - Vung Tau', 'South', 8.7318, 106.6326, 'Airport serving Con Dao'),
('dien_bien_airport', 'San bay Dien Bien', 'airport', 'Dien Bien', 'North', 21.3975, 103.0080, 'Airport serving Dien Bien'),
('ha_noi_station', 'Ga Ha Noi', 'train_station', 'Ha Noi', 'North', 21.0245, 105.8412, 'North-South railway station'),
('vinh_station', 'Ga Vinh', 'train_station', 'Nghe An', 'Central', 18.6733, 105.6922, 'North-South railway station'),
('hue_station', 'Ga Hue', 'train_station', 'Thua Thien Hue', 'Central', 16.4564, 107.5786, 'North-South railway station'),
('da_nang_station', 'Ga Da Nang', 'train_station', 'Da Nang', 'Central', 16.0703, 108.2098, 'North-South railway station'),
('nha_trang_station', 'Ga Nha Trang', 'train_station', 'Khanh Hoa', 'Central', 12.2488, 109.1843, 'North-South railway station'),
('quy_nhon_station', 'Ga Quy Nhon', 'train_station', 'Binh Dinh', 'Central', 13.7693, 109.2245, 'Railway station serving Quy Nhon'),
('sai_gon_station', 'Ga Sai Gon', 'train_station', 'TP.HCM', 'South', 10.7827, 106.6779, 'North-South railway station'),
('ha_tien_port', 'Cang Ha Tien', 'ferry_port', 'Kien Giang', 'South', 10.3833, 104.4833, 'Ferry/speedboat port for Phu Quoc'),
('phu_quoc_port', 'Cang Phu Quoc', 'ferry_port', 'Kien Giang', 'South', 10.2131, 103.9592, 'Ferry/speedboat port on Phu Quoc'),
('tran_de_port', 'Cang Tran De', 'ferry_port', 'Soc Trang', 'South', 9.4969, 106.2089, 'Speedboat port for Con Dao'),
('con_dao_port', 'Cang Con Dao', 'ferry_port', 'Ba Ria - Vung Tau', 'South', 8.6849, 106.6086, 'Ferry/speedboat port on Con Dao');

INSERT INTO transport_routes (origin_hub_id, destination_hub_id, transport_type, estimated_duration_hours, estimated_cost_vnd)
SELECT
    a.id,
    b.id,
    'flight',
    ROUND((2.0 + (
        6371 * 2 * ASIN(SQRT(LEAST(1,
            POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
            COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
            POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
        ))) / 650))::numeric, 2),
    CASE
        WHEN (6371 * 2 * ASIN(SQRT(LEAST(1,
            POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
            COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
            POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
        )))) < 300 THEN 1200000
        WHEN (6371 * 2 * ASIN(SQRT(LEAST(1,
            POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
            COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
            POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
        )))) < 700 THEN 1800000
        WHEN (6371 * 2 * ASIN(SQRT(LEAST(1,
            POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
            COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
            POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
        )))) < 1200 THEN 2500000
        ELSE 3500000
    END
FROM transport_hubs a
JOIN transport_hubs b ON a.type = 'airport' AND b.type = 'airport' AND a.code < b.code;

INSERT INTO transport_routes (origin_hub_id, destination_hub_id, transport_type, estimated_duration_hours, estimated_cost_vnd)
SELECT a.id, b.id, 'train',
       ROUND((6371 * 2 * ASIN(SQRT(LEAST(1,
           POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
           COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
           POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
       ))) / 55)::numeric, 2),
       GREATEST(160000, ROUND((6371 * 2 * ASIN(SQRT(LEAST(1,
           POWER(SIN(RADIANS(b.latitude - a.latitude) / 2), 2) +
           COS(RADIANS(a.latitude)) * COS(RADIANS(b.latitude)) *
           POWER(SIN(RADIANS(b.longitude - a.longitude) / 2), 2)
       ))) * 950)::numeric, 0))
FROM transport_hubs a
JOIN transport_hubs b ON a.type = 'train_station' AND b.type = 'train_station' AND a.code < b.code;

INSERT INTO transport_routes (origin_hub_id, destination_hub_id, transport_type, estimated_duration_hours, estimated_cost_vnd)
SELECT p1.id, p2.id, 'ferry', 2.5, 250000
FROM transport_hubs p1
JOIN transport_hubs p2 ON p1.code = 'ha_tien_port' AND p2.code = 'phu_quoc_port'
UNION ALL
SELECT p1.id, p2.id, 'ferry', 2.25, 390000
FROM transport_hubs p1
JOIN transport_hubs p2 ON p1.code = 'tran_de_port' AND p2.code = 'con_dao_port';

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
