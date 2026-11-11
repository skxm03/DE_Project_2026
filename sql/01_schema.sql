\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA gmaps;
SET search_path TO gmaps;

CREATE TABLE cities (
    city_id integer PRIMARY KEY,
    city_name text NOT NULL UNIQUE,
    center_lat numeric(8,6) NOT NULL CHECK (center_lat BETWEEN -90 AND 90),
    center_lng numeric(9,6) NOT NULL CHECK (center_lng BETWEEN -180 AND 180)
);

CREATE TABLE place_categories (
    category_id integer PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE places (
    place_id integer PRIMARY KEY,
    plus_code varchar(11) NOT NULL UNIQUE CHECK (plus_code ~ '^[23456789CFGHJMPQRVWX]{8}[+][23456789CFGHJMPQRVWX]{2}$'),
    name text NOT NULL,
    category_id integer NOT NULL REFERENCES place_categories ON DELETE RESTRICT,
    city_id integer NOT NULL REFERENCES cities ON DELETE RESTRICT,
    latitude numeric(8,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude numeric(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    address text NOT NULL,
    phone text NULL,
    website text NULL,
    price_level smallint NULL CHECK (price_level BETWEEN 1 AND 4),
    avg_rating numeric(2,1) NULL CHECK (avg_rating BETWEEN 1 AND 5),
    review_count integer NOT NULL CHECK (review_count >= 0),
    is_permanently_closed boolean NOT NULL,
    created_at timestamptz NOT NULL
);

CREATE TABLE opening_hours (
    place_id integer NOT NULL REFERENCES places ON DELETE CASCADE,
    weekday smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    opens time NOT NULL CHECK (opens < TIME '24:00'),
    closes time NOT NULL CHECK (closes <> opens),
    PRIMARY KEY (place_id, weekday)
);

CREATE TABLE users (
    user_id integer PRIMARY KEY,
    display_name text NOT NULL,
    email text NOT NULL UNIQUE,
    home_city_id integer NULL REFERENCES cities ON DELETE SET NULL,
    is_local_guide boolean NOT NULL,
    guide_level smallint NULL CHECK (guide_level BETWEEN 1 AND 10),
    created_at timestamptz NOT NULL,
    CHECK (is_local_guide = (guide_level IS NOT NULL))
);

CREATE TABLE place_reviews (
    review_id integer PRIMARY KEY,
    place_id integer NOT NULL REFERENCES places ON DELETE CASCADE,
    user_id integer NOT NULL REFERENCES users ON DELETE CASCADE,
    rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text text NULL,
    photo_count integer NOT NULL CHECK (photo_count >= 0),
    created_at timestamptz NOT NULL,
    UNIQUE (place_id, user_id)
);

CREATE TABLE saved_places (
    user_id integer NOT NULL REFERENCES users ON DELETE CASCADE,
    place_id integer NOT NULL REFERENCES places ON DELETE CASCADE,
    list_name text NOT NULL CHECK (list_name IN ('Want to go', 'Starred', 'Favourites', 'Travel plans')),
    saved_at timestamptz NOT NULL,
    PRIMARY KEY (user_id, place_id, list_name)
);

CREATE TABLE road_segments (
    segment_id integer PRIMARY KEY,
    road_name text NOT NULL,
    city_id integer NOT NULL REFERENCES cities ON DELETE RESTRICT,
    road_type text NOT NULL CHECK (road_type IN ('ARTERIAL', 'LOCAL', 'HIGHWAY')),
    start_lat numeric(8,6) NOT NULL CHECK (start_lat BETWEEN -90 AND 90),
    start_lng numeric(9,6) NOT NULL CHECK (start_lng BETWEEN -180 AND 180),
    end_lat numeric(8,6) NOT NULL CHECK (end_lat BETWEEN -90 AND 90),
    end_lng numeric(9,6) NOT NULL CHECK (end_lng BETWEEN -180 AND 180),
    length_m integer NOT NULL CHECK (length_m > 0),
    speed_limit_kmph smallint NOT NULL CHECK (speed_limit_kmph > 0)
);

CREATE TABLE traffic_readings (
    reading_id integer PRIMARY KEY,
    segment_id integer NOT NULL REFERENCES road_segments ON DELETE CASCADE,
    recorded_at timestamptz NOT NULL,
    avg_speed_kmph numeric(5,1) NOT NULL CHECK (avg_speed_kmph >= 0),
    congestion_level text NOT NULL CHECK (congestion_level IN ('LOW', 'MODERATE', 'HEAVY', 'STANDSTILL')),
    UNIQUE (segment_id, recorded_at)
);

CREATE TABLE navigation_sessions (
    session_id bigint PRIMARY KEY,
    user_id integer NULL REFERENCES users ON DELETE SET NULL,
    origin_place_id integer NULL REFERENCES places ON DELETE SET NULL,
    origin_lat numeric(8,6) NOT NULL CHECK (origin_lat BETWEEN -90 AND 90),
    origin_lng numeric(9,6) NOT NULL CHECK (origin_lng BETWEEN -180 AND 180),
    dest_place_id integer NOT NULL REFERENCES places ON DELETE RESTRICT,
    travel_mode text NOT NULL CHECK (travel_mode IN ('DRIVE', 'TRANSIT', 'WALK', 'TWO_WHEELER')),
    started_at timestamptz NOT NULL,
    distance_km numeric(8,2) NOT NULL CHECK (distance_km >= 0),
    eta_minutes integer NOT NULL CHECK (eta_minutes > 0),
    actual_minutes integer NULL CHECK (actual_minutes > 0),
    rerouted_count integer NOT NULL DEFAULT 0 CHECK (rerouted_count >= 0),
    status text NOT NULL CHECK (status IN ('COMPLETED', 'CANCELLED', 'IN_PROGRESS')),
    CHECK ((status = 'COMPLETED') = (actual_minutes IS NOT NULL))
);

CREATE TABLE incident_reports (
    report_id integer PRIMARY KEY,
    segment_id integer NOT NULL REFERENCES road_segments ON DELETE CASCADE,
    user_id integer NOT NULL REFERENCES users ON DELETE RESTRICT,
    incident_type text NOT NULL CHECK (incident_type IN ('ROADWORK', 'POLICE', 'CLOSURE', 'WATERLOGGING', 'ACCIDENT', 'BREAKDOWN')),
    reported_at timestamptz NOT NULL,
    expires_at timestamptz NOT NULL CHECK (expires_at > reported_at),
    upvotes integer NOT NULL CHECK (upvotes >= 0)
);

COMMIT;
