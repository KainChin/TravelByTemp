-- Content management tables for AI Travel Admin dashboard

ALTER TABLE destinations ADD COLUMN IF NOT EXISTS view_count BIGINT NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS content_articles (
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

CREATE TABLE IF NOT EXISTS content_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_content_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    link_url VARCHAR(500),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS gallery_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    destination_id UUID,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_gallery_images_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS featured_content (
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

CREATE INDEX IF NOT EXISTS idx_content_articles_status ON content_articles(status);
CREATE INDEX IF NOT EXISTS idx_content_articles_type ON content_articles(article_type);
CREATE INDEX IF NOT EXISTS idx_content_articles_author ON content_articles(author_id);
CREATE INDEX IF NOT EXISTS idx_content_articles_created_at ON content_articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_activity_logs_created_at ON content_activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_destinations_view_count ON destinations(view_count DESC);

UPDATE destinations SET view_count = CASE slug
    WHEN 'da-nang' THEN 125600
    WHEN 'phu-quoc' THEN 118400
    WHEN 'pho-co-hoi-an' THEN 98700
    WHEN 'thanh-pho-da-lat' THEN 87200
    WHEN 'ha-noi' THEN 76500
    WHEN 'vinh-ha-long' THEN 65400
    WHEN 'hue' THEN 54300
    WHEN 'sapa' THEN 43200
    ELSE 10000 + (ABS(hashtext(slug::text)) % 50000)
END WHERE view_count = 0;
