-- Migration 003: Create amenities and listing_amenities tables

-- Master list of amenities
CREATE TABLE amenities (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    category   VARCHAR(50) NOT NULL,
    icon       VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Junction table for many-to-many relationship
CREATE TABLE listing_amenities (
    listing_id BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    amenity_id BIGINT NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
    PRIMARY KEY (listing_id, amenity_id)
);

-- Indexes for performance
CREATE INDEX idx_listing_amenities_amenity_id ON listing_amenities(amenity_id);
-- Note: Primary key already indexes listing_id, and FKs help with joins