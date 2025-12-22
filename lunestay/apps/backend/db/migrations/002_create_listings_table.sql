
-- Migration 002: Enable PostGIS and create listings table

-- Enable PostGIS extension (only needs to run once)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- Optional: for future UUIDs

-- Create listings table
CREATE TABLE listings (
    id                   BIGSERIAL PRIMARY KEY,
    host_id              BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title                VARCHAR(150) NOT NULL,
    description          TEXT NOT NULL,
    property_type        VARCHAR(50) NOT NULL,
    room_type            VARCHAR(50) NOT NULL,
    guest_capacity       SMALLINT NOT NULL CHECK (guest_capacity > 0),
    bedrooms             SMALLINT NOT NULL CHECK (bedrooms >= 0),
    beds                 SMALLINT NOT NULL CHECK (beds > 0),
    bathrooms            NUMERIC(3,1) NOT NULL CHECK (bathrooms > 0),
    price_per_night      NUMERIC(10,2) NOT NULL CHECK (price_per_night > 0),
    cleaning_fee         NUMERIC(10,2) DEFAULT 0,
    security_deposit     NUMERIC(10,2) DEFAULT 0,
    location_lat         DOUBLE PRECISION NOT NULL,
    location_lng         DOUBLE PRECISION NOT NULL,
    location_address     TEXT NOT NULL,
    location_city        VARCHAR(100) NOT NULL,
    location_country     VARCHAR(100) NOT NULL,
    location_geom        GEOMETRY(Point, 4326) NOT NULL,
    is_active            BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_listings_host_id ON listings(host_id);
CREATE INDEX idx_listings_price_per_night ON listings(price_per_night);
CREATE INDEX idx_listings_is_active ON listings(is_active);

-- Critical: GIST index for fast geo queries (e.g., within 10km)
CREATE INDEX idx_listings_location_geom ON listings USING GIST (location_geom);

-- Partial index for only active listings (most searches filter on active)
CREATE INDEX idx_listings_active_geom ON listings USING GIST (location_geom) WHERE is_active = true;

-- Trigger for updated_at
CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();