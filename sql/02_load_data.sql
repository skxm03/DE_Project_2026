\set ON_ERROR_STOP on
BEGIN;
SET search_path TO gmaps;
SET TIME ZONE 'Asia/Kolkata';
\copy cities (city_id, city_name, center_lat, center_lng) FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER MATCH)
\copy place_categories (category_id, category_name) FROM 'seed_data/place_categories.csv' WITH (FORMAT csv, HEADER MATCH)
\copy places (place_id, plus_code, name, category_id, city_id, latitude, longitude, address, phone, website, price_level, avg_rating, review_count, is_permanently_closed, created_at) FROM 'seed_data/places.csv' WITH (FORMAT csv, HEADER MATCH)
\copy opening_hours (place_id, weekday, opens, closes) FROM 'seed_data/opening_hours.csv' WITH (FORMAT csv, HEADER MATCH)
\copy users (user_id, display_name, email, home_city_id, is_local_guide, guide_level, created_at) FROM 'seed_data/users.csv' WITH (FORMAT csv, HEADER MATCH)
\copy place_reviews (review_id, place_id, user_id, rating, review_text, photo_count, created_at) FROM 'seed_data/place_reviews.csv' WITH (FORMAT csv, HEADER MATCH)
\copy saved_places (user_id, place_id, list_name, saved_at) FROM 'seed_data/saved_places.csv' WITH (FORMAT csv, HEADER MATCH)
\copy road_segments (segment_id, road_name, city_id, road_type, start_lat, start_lng, end_lat, end_lng, length_m, speed_limit_kmph) FROM 'seed_data/road_segments.csv' WITH (FORMAT csv, HEADER MATCH)
\copy traffic_readings (reading_id, segment_id, recorded_at, avg_speed_kmph, congestion_level) FROM 'seed_data/traffic_readings.csv' WITH (FORMAT csv, HEADER MATCH)
\copy navigation_sessions (session_id, user_id, origin_place_id, origin_lat, origin_lng, dest_place_id, travel_mode, started_at, distance_km, eta_minutes, actual_minutes, rerouted_count, status) FROM 'seed_data/navigation_sessions.csv' WITH (FORMAT csv, HEADER MATCH)
\copy incident_reports (report_id, segment_id, user_id, incident_type, reported_at, expires_at, upvotes) FROM 'seed_data/incident_reports.csv' WITH (FORMAT csv, HEADER MATCH)

ANALYZE;
COMMIT;
