SET search_path TO gmaps;
-- R01: narrow restaurant search to the latitude/longitude box.
CREATE INDEX cp3_places_nearby ON places(category_id, latitude, longitude)
WHERE NOT is_permanently_closed;
-- R08: alerts only; restrict by the timestamp and retrieve segment IDs.
CREATE INDEX cp3_traffic_alert_time ON traffic_readings(recorded_at DESC, segment_id)
WHERE congestion_level IN ('HEAVY', 'STANDSTILL');
-- R10: indexed local day range; supplies newest-first order.
CREATE INDEX cp3_incidents_reported_at ON incident_reports(reported_at DESC);
-- R20: benchmark the bounded reporting window without changing R12’s tied top ten.
CREATE INDEX cp3_nav_june_started ON navigation_sessions(started_at)
WHERE started_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
  AND started_at < TIMESTAMPTZ '2026-07-01 00:00:00+05:30';
-- R19: count and find the last trip to one hospital.
CREATE INDEX cp3_nav_destination_started ON navigation_sessions(dest_place_id, started_at);
-- R13: only actual origin listings can disqualify a place.
CREATE INDEX cp3_nav_origin_place ON navigation_sessions(origin_place_id)
WHERE origin_place_id IS NOT NULL;
-- R22: can walk in the requested order through the page offset.
CREATE INDEX cp3_reviews_moderation ON place_reviews(created_at DESC)
INCLUDE (review_id, place_id, user_id, rating);

-- CP4 Scale Optimizations:
-- R04: Open now filter with rating order for Bangalore restaurants.
CREATE INDEX IF NOT EXISTS cp4_places_open_now ON places(city_id, category_id, avg_rating DESC NULLS LAST, place_id)
WHERE NOT is_permanently_closed;
-- R04: Covering index for weekday opening and closing hours.
CREATE INDEX IF NOT EXISTS cp4_opening_hours_covering ON opening_hours(place_id, weekday) INCLUDE (opens, closes);
-- R05: Newest reviews for a given place.
CREATE INDEX IF NOT EXISTS cp4_reviews_place_created ON place_reviews(place_id, created_at DESC);
-- R07: Prefix search on road name in Bangalore.
CREATE INDEX IF NOT EXISTS cp4_road_segments_filter ON road_segments(city_id, road_name text_pattern_ops, segment_id);
-- R07: Covering index on traffic readings for instant segment lookup.
CREATE INDEX IF NOT EXISTS cp4_traffic_covering ON traffic_readings(segment_id, recorded_at DESC, avg_speed_kmph, congestion_level);
-- R12: Recent trips by destination place.
CREATE INDEX IF NOT EXISTS cp4_nav_recent_started ON navigation_sessions(started_at, dest_place_id);

