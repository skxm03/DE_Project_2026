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
