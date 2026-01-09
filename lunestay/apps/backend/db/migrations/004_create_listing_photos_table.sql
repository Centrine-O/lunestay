-- Migration 004: Create listing_photos table

CREATE TABLE listing_photos (
    id          BIGSERIAL PRIMARY KEY,
    listing_id  BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    url         TEXT NOT NULL,
    key         TEXT NOT NULL,               -- MinIO object key (for management)
    caption     TEXT,
    sort_order  SMALLINT NOT NULL DEFAULT 0,
    is_cover    BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_listing_photos_listing_id ON listing_photos(listing_id);
CREATE INDEX idx_listing_photos_listing_id_sort_order ON listing_photos(listing_id, sort_order);

-- Optional: Enforce only one cover photo per listing (via partial unique index)
CREATE UNIQUE INDEX idx_listing_photos_unique_cover
    ON listing_photos (listing_id)
    WHERE is_cover = true;