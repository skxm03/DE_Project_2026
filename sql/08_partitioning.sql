-- =====================================================================
-- CP4: Partitioning DDL and Design for Google Maps Navigation Database
-- Table: navigation_sessions
-- Strategy: RANGE partitioning on started_at (Monthly)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ARCHITECTURAL JUSTIFICATION
-- ---------------------------------------------------------------------
-- Why navigation_sessions?
-- - Volume & Growth: At 4 million rows on the large dataset and an expected
--   20x-100x volume increase next year, navigation_sessions is the highest-volume
--   append-heavy table in the system.
-- - Query Access Patterns: Major navigation queries filter on time windows:
--     * R11: Whole year 2026 (scans only 2026 partitions, skips 2025).
--     * R12: Last 7 days of June 2026 (scans only the June 2026 partition).
--     * R16: 2026 navigations to closed places (skips all 2025 partitions).
--     * R20: June 2026 daily trend & running total (scans only navigation_sessions_2026_06).
-- - Maintenance & Lifecycle: Rolling data retention. Dropping old data
--   (e.g., sessions older than 2 years) becomes an instantaneous catalog update:
--   `ALTER TABLE navigation_sessions DETACH PARTITION ...; DROP TABLE ...;`
--   instead of a massive `DELETE` causing index bloat, lock contention, and VACUUM overhead.
-- - Working Set in Memory: Each monthly partition's indexes easily fit into
--   PostgreSQL shared_buffers, dramatically reducing random disk I/O.
--
-- Why RANGE on started_at?
-- - Range partitioning on timestamps aligns perfectly with time-series session data
--   and partition pruning rules in PostgreSQL optimizer.
--
-- Primary Key Rule in PostgreSQL Partitioning:
-- - In PostgreSQL, any UNIQUE or PRIMARY KEY constraint on a partitioned table
--   MUST contain all columns in the partition key.
-- - Consequently, `PRIMARY KEY (session_id)` is not allowed on a table partitioned
--   by `started_at`. The primary key must be composite:
--   `PRIMARY KEY (session_id, started_at)`.
-- ---------------------------------------------------------------------

SET search_path TO gmaps;

-- Step 1: Create the partitioned table
CREATE TABLE IF NOT EXISTS navigation_sessions_partitioned (
    session_id bigint NOT NULL,
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
    CHECK ((status = 'COMPLETED') = (actual_minutes IS NOT NULL)),
    PRIMARY KEY (session_id, started_at)
) PARTITION BY RANGE (started_at);

-- Step 2: Create monthly partitions for 2025 and 2026
CREATE TABLE IF NOT EXISTS nav_sessions_2025_01 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+05:30') TO ('2025-02-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_02 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-02-01 00:00:00+05:30') TO ('2025-03-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_03 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-03-01 00:00:00+05:30') TO ('2025-04-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_04 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-04-01 00:00:00+05:30') TO ('2025-05-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_05 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-05-01 00:00:00+05:30') TO ('2025-06-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_06 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-06-01 00:00:00+05:30') TO ('2025-07-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_07 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-07-01 00:00:00+05:30') TO ('2025-08-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_08 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-08-01 00:00:00+05:30') TO ('2025-09-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_09 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-09-01 00:00:00+05:30') TO ('2025-10-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_10 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-10-01 00:00:00+05:30') TO ('2025-11-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_11 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-11-01 00:00:00+05:30') TO ('2025-12-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2025_12 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2025-12-01 00:00:00+05:30') TO ('2026-01-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS nav_sessions_2026_01 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+05:30') TO ('2026-02-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_02 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-02-01 00:00:00+05:30') TO ('2026-03-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_03 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-03-01 00:00:00+05:30') TO ('2026-04-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_04 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00+05:30') TO ('2026-05-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_05 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-05-01 00:00:00+05:30') TO ('2026-06-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_06 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-06-01 00:00:00+05:30') TO ('2026-07-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_07 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-07-01 00:00:00+05:30') TO ('2026-08-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_08 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-08-01 00:00:00+05:30') TO ('2026-09-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_09 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-09-01 00:00:00+05:30') TO ('2026-10-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_10 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-10-01 00:00:00+05:30') TO ('2026-11-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_11 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-11-01 00:00:00+05:30') TO ('2026-12-01 00:00:00+05:30');
CREATE TABLE IF NOT EXISTS nav_sessions_2026_12 PARTITION OF navigation_sessions_partitioned
    FOR VALUES FROM ('2026-12-01 00:00:00+05:30') TO ('2027-01-01 00:00:00+05:30');

-- Default partition for upcoming traffic beyond 2026
CREATE TABLE IF NOT EXISTS nav_sessions_default PARTITION OF navigation_sessions_partitioned DEFAULT;

-- Step 3: Local indexes on the partitioned table
-- PostgreSQL propagates these index definitions across all child partitions automatically.
CREATE INDEX IF NOT EXISTS part_nav_dest_started ON navigation_sessions_partitioned(dest_place_id, started_at);
CREATE INDEX IF NOT EXISTS part_nav_origin_place ON navigation_sessions_partitioned(origin_place_id)
    WHERE origin_place_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS part_nav_started_at ON navigation_sessions_partitioned(started_at);

-- ---------------------------------------------------------------------
-- 4. VERIFICATION OF PARTITION PRUNING
-- ---------------------------------------------------------------------
-- Query R20 restricted to June 2026:
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT day, sessions, sum(sessions) OVER (ORDER BY day) AS running_total
-- FROM (
--     SELECT started_at::date AS day, count(*) AS sessions
--     FROM navigation_sessions_partitioned
--     WHERE started_at >= '2026-06-01'::timestamptz
--       AND started_at < '2026-07-01'::timestamptz
--     GROUP BY 1
-- ) d
-- ORDER BY day;
--
-- Expected execution plan behavior:
-- The optimizer eliminates 23 out of 24 monthly partitions at planning/execution time,
-- performing scans exclusively on `nav_sessions_2026_06`.
-- ---------------------------------------------------------------------
