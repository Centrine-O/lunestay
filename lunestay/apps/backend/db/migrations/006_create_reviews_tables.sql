-- Migration 006: Create listing_reviews and host_reviews tables

-- Reviews by guests about the listing and host
CREATE TABLE listing_reviews (
    id                     BIGSERIAL PRIMARY KEY,
    listing_id             BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    booking_id             BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    guest_id               BIGINT NOT NULL REFERENCES users(id),
    host_id                BIGINT NOT NULL REFERENCES users(id),
    rating_overall         SMALLINT NOT NULL CHECK (rating_overall BETWEEN 1 AND 5),
    rating_cleanliness     SMALLINT NOT NULL CHECK (rating_cleanliness BETWEEN 1 AND 5),
    rating_communication   SMALLINT NOT NULL CHECK (rating_communication BETWEEN 1 AND 5),
    rating_checkin         SMALLINT NOT NULL CHECK (rating_checkin BETWEEN 1 AND 5),
    rating_location        SMALLINT NOT NULL CHECK (rating_location BETWEEN 1 AND 5),
    rating_value           SMALLINT NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
    comment                TEXT NOT NULL,
    response_from_host     TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (booking_id)
);

-- Reviews by hosts about their guests
CREATE TABLE host_reviews (
    id                     BIGSERIAL PRIMARY KEY,
    booking_id             BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    host_id                BIGINT NOT NULL REFERENCES users(id),
    guest_id               BIGINT NOT NULL REFERENCES users(id),
    rating_overall         SMALLINT NOT NULL CHECK (rating_overall BETWEEN 1 AND 5),
    rating_communication   SMALLINT NOT NULL CHECK (rating_communication BETWEEN 1 AND 5),
    rating_cleanliness     SMALLINT NOT NULL CHECK (rating_cleanliness BETWEEN 1 AND 5),
    rating_house_rules     SMALLINT NOT NULL CHECK (rating_house_rules BETWEEN 1 AND 5),
    comment                TEXT NOT NULL,
    is_recommended         BOOLEAN NOT NULL,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (booking_id)
);

-- Indexes for performance
CREATE INDEX idx_listing_reviews_listing_id ON listing_reviews(listing_id);
CREATE INDEX idx_listing_reviews_host_id ON listing_reviews(host_id);
CREATE INDEX idx_listing_reviews_booking_id ON listing_reviews(booking_id);

CREATE INDEX idx_host_reviews_guest_id ON host_reviews(guest_id);
CREATE INDEX idx_host_reviews_booking_id ON host_reviews(booking_id);