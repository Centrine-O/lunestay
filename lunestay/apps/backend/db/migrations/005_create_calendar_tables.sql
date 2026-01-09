-- Migration 005: Create blocked_dates and bookings tables

-- Dates manually blocked by the host
CREATE TABLE blocked_dates (
    id         BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    date       DATE NOT NULL,
    reason     TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (listing_id, date)
);

-- Actual guest reservations
CREATE TABLE bookings (
    id              BIGSERIAL PRIMARY KEY,
    listing_id      BIGINT NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    guest_id        BIGINT NOT NULL REFERENCES users(id),
    check_in_date   DATE NOT NULL,
    check_out_date  DATE NOT NULL,
    num_guests      SMALLINT NOT NULL CHECK (num_guests > 0),
    total_price     NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    currency        VARCHAR(3) NOT NULL DEFAULT 'USD',
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (check_out_date > check_in_date)
);

-- Indexes for performance
CREATE INDEX idx_blocked_dates_listing_id_date ON blocked_dates(listing_id, date);
CREATE INDEX idx_bookings_listing_id ON bookings(listing_id);
CREATE INDEX idx_bookings_guest_id ON bookings(guest_id);
CREATE INDEX idx_bookings_check_in_out ON bookings(listing_id, check_in_date, check_out_date);

-- Trigger for updated_at on bookings
CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();