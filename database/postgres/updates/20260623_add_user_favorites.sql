CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    destination_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_favorites_users'
    ) THEN
        ALTER TABLE user_favorites
            ADD CONSTRAINT fk_user_favorites_users
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_favorites_destinations'
    ) THEN
        ALTER TABLE user_favorites
            ADD CONSTRAINT fk_user_favorites_destinations
            FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_favorites_user_destination'
    ) THEN
        ALTER TABLE user_favorites
            ADD CONSTRAINT uq_user_favorites_user_destination
            UNIQUE (user_id, destination_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id
    ON user_favorites(user_id);

CREATE INDEX IF NOT EXISTS idx_user_favorites_destination_id
    ON user_favorites(destination_id);
