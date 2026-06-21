-- ============================================================
-- VietTravel AI · PostgreSQL Database Schema
-- Engine: PostgreSQL 15+
-- Convention: UUID PK, soft-delete, UTC timestamps (TIMESTAMPTZ)
-- Generated from: VietTravel_AI_Database_Architecture.docx
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- gen_random_uuid()

-- ─── 1. USERS ───────────────────────────────────────────────
CREATE TABLE users (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email              VARCHAR(255) NOT NULL,
    phone_number       VARCHAR(20),
    password_hash      TEXT NOT NULL,
    full_name          VARCHAR(150) NOT NULL,
    avatar_url         TEXT,
    date_of_birth      DATE,
    gender             VARCHAR(20) CHECK (gender IN ('male','female','other','prefer_not_to_say')),
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    is_email_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at      TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ,
    is_deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_phone UNIQUE (phone_number)
);

-- ─── 2. REFRESH TOKENS ──────────────────────────────────────
CREATE TABLE refresh_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash   TEXT NOT NULL,
    device_info  JSONB,
    ip_address   INET,
    expires_at   TIMESTAMPTZ NOT NULL,
    is_revoked   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,
    is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_refresh_token_hash UNIQUE (token_hash)
);

-- ─── 3. PASSWORD RESET TOKENS ───────────────────────────────
CREATE TABLE password_reset_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash   TEXT NOT NULL,
    expires_at   TIMESTAMPTZ NOT NULL,
    is_used      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,
    is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_pwd_reset_token_hash UNIQUE (token_hash)
);

-- ─── 4. USER FAVORITES ──────────────────────────────────────
CREATE TABLE user_favorites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id         VARCHAR(100) NOT NULL,
    item_type       VARCHAR(50) NOT NULL CHECK (item_type IN ('destination','article','hotel','food','cafe')),
    item_name       VARCHAR(255),
    item_thumbnail  TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_user_favorite UNIQUE (user_id, item_id, item_type)
);

-- ─── 5. CONVERSATIONS ───────────────────────────────────────
CREATE TABLE conversations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(255),
    status              VARCHAR(20) NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active','archived','completed')),
    context_summary     TEXT,
    total_tokens_used   INTEGER NOT NULL DEFAULT 0,
    ai_model            VARCHAR(100),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 6. TRIPS ───────────────────────────────────────────────
CREATE TABLE trips (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id       UUID REFERENCES conversations(id) ON DELETE SET NULL,
    title                 VARCHAR(255) NOT NULL,
    destination_name      VARCHAR(255) NOT NULL,
    destination_province  VARCHAR(100),
    start_date            DATE,
    end_date              DATE,
    number_of_days        SMALLINT CHECK (number_of_days > 0),
    status                VARCHAR(20) NOT NULL DEFAULT 'draft'
                              CHECK (status IN ('draft','planned','ongoing','completed','cancelled')),
    budget                NUMERIC(15,2) CHECK (budget >= 0),
    estimated_cost        NUMERIC(15,2) CHECK (estimated_cost >= 0),
    actual_cost           NUMERIC(15,2) CHECK (actual_cost >= 0),
    cover_image_url       TEXT,
    notes                 TEXT,
    is_archived           BOOLEAN NOT NULL DEFAULT FALSE,
    duplicated_from_id    UUID REFERENCES trips(id) ON DELETE SET NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at            TIMESTAMPTZ,
    is_deleted            BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 7. TRIP DAYS ───────────────────────────────────────────
CREATE TABLE trip_days (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id     UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    day_number  SMALLINT NOT NULL CHECK (day_number > 0),
    day_date    DATE,
    title       VARCHAR(255),
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_trip_day_number UNIQUE (trip_id, day_number)
);

-- ─── 8. TRIP ACTIVITIES ─────────────────────────────────────
CREATE TABLE trip_activities (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_day_id       UUID NOT NULL REFERENCES trip_days(id) ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    location_name     VARCHAR(255),
    location_ref_id   VARCHAR(100),
    activity_type     VARCHAR(50) CHECK (activity_type IN ('checkin','sightseeing','food','transport','shopping','other')),
    start_time        TIME,
    end_time          TIME,
    estimated_cost    NUMERIC(12,2) CHECK (estimated_cost >= 0),
    actual_cost       NUMERIC(12,2) CHECK (actual_cost >= 0),
    sort_order        SMALLINT NOT NULL DEFAULT 0,
    is_ai_generated   BOOLEAN NOT NULL DEFAULT FALSE,
    ai_confidence     NUMERIC(4,3) CHECK (ai_confidence BETWEEN 0 AND 1),
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ,
    is_deleted        BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 9. MESSAGES ────────────────────────────────────────────
CREATE TABLE messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role                VARCHAR(20) NOT NULL CHECK (role IN ('user','assistant','system')),
    content             TEXT NOT NULL,
    content_type        VARCHAR(30) NOT NULL DEFAULT 'text'
                            CHECK (content_type IN ('text','itinerary','suggestion','tip')),
    prompt_tokens       INTEGER,
    completion_tokens   INTEGER,
    ai_model            VARCHAR(100),
    metadata            JSONB,
    sort_order          INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 10. LANDMARK RECOGNITIONS ──────────────────────────────
CREATE TABLE landmark_recognitions (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url                TEXT NOT NULL,
    image_hash               VARCHAR(64),
    recognized_place_name    VARCHAR(255),
    recognized_place_ref_id  VARCHAR(100),
    confidence_score         NUMERIC(4,3) CHECK (confidence_score BETWEEN 0 AND 1),
    recognition_time_ms      INTEGER,
    ai_model                 VARCHAR(100),
    raw_ai_response          JSONB,
    linked_trip_id           UUID REFERENCES trips(id) ON DELETE SET NULL,
    status                   VARCHAR(20) NOT NULL DEFAULT 'pending'
                                 CHECK (status IN ('pending','completed','failed')),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at               TIMESTAMPTZ,
    is_deleted               BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 11. USER PREFERENCE TAGS ───────────────────────────────
CREATE TABLE user_preference_tags (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tag         VARCHAR(50) NOT NULL
                    CHECK (tag IN ('photography','foodie','nature','adventure',
                                   'luxury','budget','family','couple','culture')),
    weight      NUMERIC(4,3) NOT NULL DEFAULT 0.5 CHECK (weight BETWEEN 0 AND 1),
    source      VARCHAR(30) NOT NULL DEFAULT 'manual'
                    CHECK (source IN ('manual','inferred_trips','inferred_chat','inferred_saves')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_user_tag UNIQUE (user_id, tag)
);

-- ─── 12. RECOMMENDATION LOGS ────────────────────────────────
CREATE TABLE recommendation_logs (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_type    VARCHAR(50) NOT NULL
                               CHECK (recommendation_type IN ('destination','food','hotel','trip_idea','activity')),
    recommended_item_id    VARCHAR(100),
    recommended_item_name  VARCHAR(255),
    reason_tags            TEXT[],
    ai_model               VARCHAR(100),
    score                  NUMERIC(5,4),
    was_viewed             BOOLEAN NOT NULL DEFAULT FALSE,
    was_saved              BOOLEAN NOT NULL DEFAULT FALSE,
    was_tripped            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at             TIMESTAMPTZ,
    is_deleted             BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── 13. NOTIFICATIONS ──────────────────────────────────────
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL
                    CHECK (type IN ('trip_created','trip_updated','trip_reminder',
                                    'ai_suggestion','recommendation','system')),
    title       VARCHAR(255) NOT NULL,
    message     TEXT NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    read_at     TIMESTAMPTZ,
    action_url  TEXT,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- UPDATED_AT TRIGGER (auto-update updated_at on every UPDATE)
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DO $$ DECLARE t TEXT;
BEGIN FOR t IN SELECT unnest(ARRAY[
  'users','refresh_tokens','password_reset_tokens','user_favorites',
  'conversations','trips','trip_days','trip_activities','messages',
  'landmark_recognitions','user_preference_tags',
  'recommendation_logs','notifications'
]) LOOP
  EXECUTE format('CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
END LOOP; END; $$;

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_users_email           ON users (email);
CREATE INDEX idx_users_active          ON users (id) WHERE is_deleted = FALSE;
CREATE INDEX idx_rt_user_id            ON refresh_tokens (user_id);
CREATE INDEX idx_rt_token_hash         ON refresh_tokens (token_hash);
CREATE INDEX idx_prt_user_id           ON password_reset_tokens (user_id);
CREATE INDEX idx_uf_user_type          ON user_favorites (user_id, item_type);
CREATE INDEX idx_trips_user_id         ON trips (user_id);
CREATE INDEX idx_trips_user_status     ON trips (user_id, status);
CREATE INDEX idx_trips_active          ON trips (user_id) WHERE is_deleted = FALSE AND is_archived = FALSE;
CREATE INDEX idx_td_trip_id            ON trip_days (trip_id);
CREATE INDEX idx_ta_trip_day_id        ON trip_activities (trip_day_id);
CREATE INDEX idx_ta_sort               ON trip_activities (trip_day_id, sort_order);
CREATE INDEX idx_conv_user_id          ON conversations (user_id);
CREATE INDEX idx_conv_status           ON conversations (status);
CREATE INDEX idx_msg_conv_sort         ON messages (conversation_id, sort_order);
CREATE INDEX idx_messages_metadata     ON messages USING GIN (metadata);
CREATE INDEX idx_lr_user_id            ON landmark_recognitions (user_id);
CREATE INDEX idx_lr_status             ON landmark_recognitions (status);
CREATE INDEX idx_upt_user_id           ON user_preference_tags (user_id);
CREATE INDEX idx_rl_user_id            ON recommendation_logs (user_id);
CREATE INDEX idx_notif_unread          ON notifications (user_id) WHERE is_read = FALSE;

-- ============================================================
-- ROW LEVEL SECURITY (apply per Section 9.2 of architecture doc)
-- Uncomment and adapt if the application sets app.current_user_id
-- ============================================================
-- ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY trips_user_policy ON trips
--   USING (user_id = current_setting('app.current_user_id')::UUID);

-- ============================================================
-- SEED DATA (Development / Testing)
-- ============================================================

-- Sample user (password: "Password123!" bcrypt hashed)
INSERT INTO users (id, email, password_hash, full_name, gender, is_active, is_email_verified)
VALUES (
  'a1b2c3d4-0000-0000-0000-000000000001',
  'nguyen.van.an@example.com',
  '$2a$12$examplehashexamplehashexamplehash12345678901234',
  'Nguyễn Văn An',
  'male',
  TRUE, TRUE
);

-- Sample conversation (AI chat about Da Lat)
INSERT INTO conversations (id, user_id, title, status, ai_model, total_tokens_used)
VALUES (
  'c0000001-0000-0000-0000-000000000001',
  'a1b2c3d4-0000-0000-0000-000000000001',
  'Lên kế hoạch du lịch Đà Lạt',
  'completed',
  'gemini-1.5-pro',
  3450
);

-- Sample messages
INSERT INTO messages (conversation_id, role, content, content_type, sort_order, completion_tokens, ai_model)
VALUES
  ('c0000001-0000-0000-0000-000000000001', 'user',
   'Tôi có 5 triệu VND. Gợi ý hành trình 3 ngày ở Đà Lạt.', 'text', 1, NULL, NULL),
  ('c0000001-0000-0000-0000-000000000001', 'assistant',
   'Với 5 triệu VND, đây là hành trình 3D2N tuyệt vời cho Đà Lạt...', 'itinerary', 2, 820, 'gemini-1.5-pro');

-- Sample trip (created from conversation)
INSERT INTO trips (id, user_id, conversation_id, title, destination_name, destination_province,
                   start_date, end_date, number_of_days, status, budget)
VALUES (
  '700a0001-0000-0000-0000-000000000001',
  'a1b2c3d4-0000-0000-0000-000000000001',
  'c0000001-0000-0000-0000-000000000001',
  'Đà Lạt 3D2N - Mùa hoa',
  'Đà Lạt', 'Lâm Đồng',
  '2025-12-20', '2025-12-22',
  3, 'planned', 5000000
);

-- Trip days
INSERT INTO trip_days (id, trip_id, day_number, day_date, title) VALUES
  ('da000001-0000-0000-0000-000000000001', '700a0001-0000-0000-0000-000000000001', 1, '2025-12-20', 'Khám phá trung tâm'),
  ('da000002-0000-0000-0000-000000000001', '700a0001-0000-0000-0000-000000000001', 2, '2025-12-21', 'LangBiang & thiên nhiên'),
  ('da000003-0000-0000-0000-000000000001', '700a0001-0000-0000-0000-000000000001', 3, '2025-12-22', 'Mua sắm & về nhà');

-- Trip activities - Day 1
INSERT INTO trip_activities (trip_day_id, title, activity_type, sort_order, is_ai_generated, estimated_cost) VALUES
  ('da000001-0000-0000-0000-000000000001', 'Check-in khách sạn', 'checkin', 1, TRUE, 400000),
  ('da000001-0000-0000-0000-000000000001', 'Hồ Xuân Hương buổi chiều', 'sightseeing', 2, TRUE, 0),
  ('da000001-0000-0000-0000-000000000001', 'Chợ Đêm Đà Lạt', 'food', 3, TRUE, 200000);

-- Saved items
INSERT INTO user_favorites (user_id, item_id, item_type, item_name) VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'destination_dalat', 'destination', 'Đà Lạt'),
  ('a1b2c3d4-0000-0000-0000-000000000001', 'hotel_023', 'hotel', 'Dalat Palace Heritage Hotel'),
  ('a1b2c3d4-0000-0000-0000-000000000001', 'food_banh_mi_hoa', 'food', 'Bánh Mì Hoa');

-- User preference tags
INSERT INTO user_preference_tags (user_id, tag, weight, source) VALUES
  ('a1b2c3d4-0000-0000-0000-000000000001', 'photography', 0.9, 'manual'),
  ('a1b2c3d4-0000-0000-0000-000000000001', 'nature', 0.8, 'inferred_trips'),
  ('a1b2c3d4-0000-0000-0000-000000000001', 'foodie', 0.7, 'inferred_saves'),
  ('a1b2c3d4-0000-0000-0000-000000000001', 'budget', 0.6, 'inferred_chat');

-- Landmark recognition
INSERT INTO landmark_recognitions
  (user_id, image_url, recognized_place_name, confidence_score, recognition_time_ms, status, ai_model)
VALUES (
  'a1b2c3d4-0000-0000-0000-000000000001',
  'https://cdn.viettravel.app/uploads/a1b2.jpg',
  'Hồ Xuân Hương, Đà Lạt',
  0.947, 1230, 'completed', 'google-vision-v1'
);

-- Notification
INSERT INTO notifications (user_id, type, title, message, action_url)
VALUES (
  'a1b2c3d4-0000-0000-0000-000000000001',
  'trip_created',
  'Chuyến đi đã được tạo!',
  'Hành trình Đà Lạt 3D2N của bạn đã sẵn sàng.',
  '/trips/700a0001-0000-0000-0000-000000000001'
);