# Lunestay Database Schema Design

Designed step-by-step for deep learning.
Using PostgreSQL 16 + PostGIS.

## 1. users table

This table stores both guests and hosts (one user can be both).

| Column            | Type                  | Constraints                  | Description |
|-------------------|-----------------------|------------------------------|-------------|
| id                | BIGSERIAL             | PRIMARY KEY                  | Auto-increment ID |
| email             | VARCHAR(255)          | NOT NULL, UNIQUE             | User's email |
| password_hash     | TEXT                  | NOT NULL                     | bcrypt hashed password |
| first_name        | VARCHAR(100)          | NOT NULL                     |             |
| last_name         | VARCHAR(100)          | NOT NULL                     |             |
| phone             | VARCHAR(50)           |                              | Optional phone |
| avatar_url        | TEXT                  |                              | Photo from MinIO |
| bio               | TEXT                  |                              | About me |
| is_host           | BOOLEAN               | NOT NULL DEFAULT false       | Can they list properties? |
| created_at        | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()       |             |
| updated_at        | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()       |             |


## 2. listings table

Stores individual properties that hosts rent out.

| Column               | Type                  | Constraints                           | Description |
|----------------------|-----------------------|---------------------------------------|-------------|
| id                   | BIGSERIAL             | PRIMARY KEY                           | Auto-increment ID |
| host_id              | BIGINT                | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Foreign key to the host (owner) |
| title                | VARCHAR(150)          | NOT NULL                              | e.g., "Cozy Mountain Cabin with View" |
| description          | TEXT                  | NOT NULL                              | Full detailed description |
| property_type        | VARCHAR(50)           | NOT NULL                              | e.g., 'house', 'apartment', 'condo', 'cabin', 'treehouse' |
| room_type            | VARCHAR(50)           | NOT NULL                              | 'entire_place', 'private_room', 'shared_room' |
| guest_capacity       | SMALLINT              | NOT NULL CHECK (guest_capacity > 0)   | Max number of guests |
| bedrooms             | SMALLINT              | NOT NULL CHECK (bedrooms >= 0)        | Number of bedrooms |
| beds                 | SMALLINT              | NOT NULL CHECK (beds > 0)             | Number of beds |
| bathrooms            | NUMERIC(3,1)          | NOT NULL CHECK (bathrooms > 0)        | e.g., 1.5 for half-bath |
| price_per_night      | NUMERIC(10,2)         | NOT NULL CHECK (price_per_night > 0)  | Base price in USD (we'll add currencies later) |
| cleaning_fee         | NUMERIC(10,2)         | DEFAULT 0                             | Optional cleaning fee |
| security_deposit     | NUMERIC(10,2)         | DEFAULT 0                             | Optional refundable deposit |
| location_lat         | DOUBLE PRECISION      | NOT NULL                              | Latitude (for map & geo-search) |
| location_lng         | DOUBLE PRECISION      | NOT NULL                              | Longitude |
| location_address     | TEXT                  | NOT NULL                              | Full formatted address |
| location_city        | VARCHAR(100)          | NOT NULL                              | City |
| location_country     | VARCHAR(100)          | NOT NULL                              | Country |
| location_geom        | GEOMETRY(Point, 4326) | NOT NULL                              | PostGIS point for fast geo queries |
| is_active            | BOOLEAN               | NOT NULL DEFAULT true                 | Host can deactivate listing |
| created_at           | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                | |
| updated_at           | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                | |


## 3. amenities table

Master list of all possible amenities (e.g., WiFi, Pool, Kitchen). We seed this with ~100 common ones.

| Column          | Type                  | Constraints                  | Description |
|-----------------|-----------------------|------------------------------|-------------|
| id              | BIGSERIAL             | PRIMARY KEY                  | Auto-increment ID |
| name            | VARCHAR(100)          | NOT NULL, UNIQUE             | e.g., "Wifi", "Pool", "Kitchen" |
| category        | VARCHAR(50)           | NOT NULL                     | Group like "Essentials", "Features", "Safety" |
| icon            | VARCHAR(100)          |                              | e.g., "wifi", "pool", "kitchen" (for frontend icons) |
| created_at      | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()       | |

## 4. listing_amenities table (junction)

Connects listings to their amenities (many-to-many).

| Column         | Type      | Constraints                                      | Description |
|----------------|-----------|--------------------------------------------------|-------------|
| listing_id     | BIGINT    | NOT NULL, REFERENCES listings(id) ON DELETE CASCADE | |
| amenity_id     | BIGINT    | NOT NULL, REFERENCES amenities(id) ON DELETE CASCADE | |
| PRIMARY KEY (listing_id, amenity_id)                               | Composite primary key (no duplicates) |


## 5. listing_photos table

Stores multiple photos per listing. Images are uploaded to MinIO (S3), we only store the URL and metadata.

| Column          | Type                  | Constraints                                      | Description |
|-----------------|-----------------------|--------------------------------------------------|-------------|
| id              | BIGSERIAL             | PRIMARY KEY                                      | Auto-increment ID |
| listing_id      | BIGINT                | NOT NULL, REFERENCES listings(id) ON DELETE CASCADE | Which listing this photo belongs to |
| url             | TEXT                  | NOT NULL                                         | Full URL in MinIO, e.g., https://localhost:9000/lunestay/123/photo1.jpg |
| key             | TEXT                  | NOT NULL                                         | Object key in MinIO bucket, e.g., listings/123/photo1.jpg |
| caption         | TEXT                  |                                                  | Optional host-provided caption |
| sort_order      | SMALLINT              | NOT NULL DEFAULT 0                               | Order photos are displayed (0 = first/primary) |
| is_cover        | BOOLEAN               | NOT NULL DEFAULT false                           | True for the main cover photo (we can enforce only one per listing later) |
| created_at      | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                           | |


## 6. blocked_dates table

Dates the host manually blocks (e.g., personal use, cleaning, maintenance). No bookings allowed on these dates.

| Column          | Type                  | Constraints                                      | Description |
|-----------------|-----------------------|--------------------------------------------------|-------------|
| id              | BIGSERIAL             | PRIMARY KEY                                      | |
| listing_id      | BIGINT                | NOT NULL, REFERENCES listings(id) ON DELETE CASCADE | |
| date            | DATE                  | NOT NULL                                         | The blocked date (midnight UTC) |
| reason          | TEXT                  |                                                  | Optional note, e.g., "Personal stay" |
| created_at      | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                           | |
| UNIQUE (listing_id, date)                                                  | Prevent duplicate blocks on same day |

## 7. bookings table

Actual reservations made by guests. This is where money and trust flow.

| Column               | Type                  | Constraints                                      | Description |
|----------------------|-----------------------|--------------------------------------------------|-------------|
| id                   | BIGSERIAL             | PRIMARY KEY                                      | |
| listing_id           | BIGINT                | NOT NULL, REFERENCES listings(id) ON DELETE CASCADE | |
| guest_id             | BIGINT                | NOT NULL, REFERENCES users(id)                   | The booking guest |
| check_in_date        | DATE                  | NOT NULL                                         | First night |
| check_out_date       | DATE                  | NOT NULL                                         | Day they leave (not inclusive) |
| num_guests           | SMALLINT              | NOT NULL CHECK (num_guests > 0)                  | |
| total_price          | NUMERIC(10,2)         | NOT NULL CHECK (total_price >= 0)                | Final amount charged (includes fees) |
| currency             | VARCHAR(3)            | NOT NULL DEFAULT 'USD'                           | e.g., USD, EUR |
| status               | VARCHAR(20)           | NOT NULL DEFAULT 'pending'                       | pending, confirmed, cancelled, completed |
| created_at           | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                           | |
| updated_at           | TIMESTAMPTZ           | NOT NULL DEFAULT NOW()                           | |
| CHECK (check_out_date > check_in_date)                                     | Prevent invalid date ranges |

