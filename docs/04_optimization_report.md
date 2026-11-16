# CP3 · Query optimization

The CP2 and CP3 tests ran on the same Mac and native PostgreSQL 18.4 server, with the same 936,328 seed rows and `Asia/Kolkata` time zone. The course helper ran each statement three times with `EXPLAIN (ANALYZE, BUFFERS)`. Writes ran individually inside transactions that rolled back. CP3 adds seven indexes and seven query rewrites; the original workload is untouched. Statistics were refreshed with `ANALYZE` after creating the indexes.

The sum of the 30 query averages went from **13,924.927 ms** to **222.871 ms**. This sum is not a production throughput estimate; R19 dominates the baseline, and R13 returns a deliberately different number of rows after the fix.

[Baseline summary](../benchmarks/results/baseline/summary.md) · [Optimized summary](../benchmarks/results/optimized/summary.md) · [Result verification](#result-verification)

## Five largest time savings

| Query | Before (ms) | After (ms) | Main change |
|---|---:|---:|---|
| R19 | 13620.371 | 3.932 | One indexed lateral count/max lookup per hospital, including zero-trip hospitals. |
| R22 | 16.636 | 3.004 | Covering descending timestamp index; OFFSET still scans past the skipped rows. |
| R16 | 13.298 | 3.875 | Statement unchanged; destination/time index is available. |
| R20 | 10.185 | 1.369 | Half-open range plus June-only time index; same running total. |
| R15 | 30.522 | 23.182 | Aggregate reviews by place first; retain the original comparison semantics. |

## All 30 query results

| Query | Before (ms) | Plan or limitation | Optimization | After (ms) | Improvement | Same result? |
|---|---:|---|---|---:|---:|---|
| R01 | 3.552 | Sequential scan of places | Partial B-tree: category first, then coordinates; closed listings omitted. | 0.129 | +96.37% | Yes · 16 rows |
| R02 | 0.039 | Two primary-key probes | Keep the existing keys and LEFT JOIN. | 0.043 | -10.26% | Yes · 1 row |
| R03 | 13.790 | Substring search and ranked top 20 | Retain original plan; rating ties at the cutoff make a different access path risky. | 13.858 | -0.49% | Yes · 20 rows |
| R04 | 9.423 | Saturday hours filter and ranked top 30 | Statement unchanged; the nearby index also helps filter restaurants. Exact IDs can vary at the tied cutoff. | 6.819 | +27.63% | Equivalent tied top 30; IDs differ |
| R05 | 0.140 | Small matching review set and sort | Keep the existing review key; extra recency index did not help in the scratch trial. | 0.132 | +5.71% | Yes · 10 rows |
| R06 | 0.186 | Few saved rows with existing key | Keep the original lookup and sort. | 0.058 | +68.82% | Yes · 4 rows |
| R07 | 3.839 | Joins and sorts readings before choosing latest | Lateral top-one probe uses the existing segment/timestamp key. | 0.248 | +93.54% | Yes · 40 rows |
| R08 | 0.366 | Queries many segments to find recent alerts | Partial B-tree on alert time first, then segment ID. | 0.119 | +67.49% | Yes · 3 rows |
| R09 | 0.349 | Reads the selected segment and groups by hour | Reuse the existing segment/timestamp key. | 0.212 | +39.26% | Yes · 24 rows |
| R10 | 0.817 | DATE() on each reported timestamp | Half-open timestamp range and descending report-time index. | 0.114 | +86.05% | Yes · 2 rows |
| R11 | 22.311 | EXTRACT(YEAR) per session | Half-open timestamp range; grouping and travel-mode keys stay unchanged. | 21.601 | +3.18% | Yes · 24 rows |
| R12 | 10.303 | Date filter, aggregation and tied top 10 | Keep the original; a general time index changed which tied IDs appeared in the scratch trial. | 4.874 | +52.69% | Yes · 10 rows |
| R13 | 20.214 | NULL in NOT IN filters out every place | Correct to NOT EXISTS; partial origin index excludes NULLs. | 6.058 | +70.03% | Intentional fix · 0 → 33,368 |
| R14 | 9.443 | Review join, aggregation and leaderboard sort | Keep the original and its tie behavior. | 5.752 | +39.09% | Yes · 20 rows |
| R15 | 30.522 | Aggregates over the review/place join | Aggregate reviews by place first; retain the original comparison semantics. | 23.182 | +24.05% | Yes · 558 rows |
| R16 | 13.298 | Joins recent trips to closed destinations | Statement unchanged; destination/time index is available. | 3.875 | +70.86% | Yes · 895 rows |
| R17 | 32.798 | Full trip aggregation by destination | Keep the original; all sessions contribute and the top-N cutoff has ties. | 30.415 | +7.27% | Yes · 20 rows |
| R18 | 14.681 | Full trip aggregation by mode | Keep the original; the rate needs the full denominator. | 14.007 | +4.59% | Yes · 4 rows |
| R19 | 13620.371 | Two correlated scans of navigation sessions per hospital | One indexed lateral count/max lookup per hospital, including zero-trip hospitals. | 3.932 | +99.97% | Yes · 1067 rows |
| R20 | 10.185 | Casts timestamps to dates to filter all sessions | Half-open range plus June-only time index; same running total. | 1.369 | +86.56% | Yes · 30 rows |
| R21 | 21.130 | Anti-join checks all places for missing hours | Keep the original and existing hours primary key. | 20.235 | +4.24% | Yes · 3 rows |
| R22 | 16.636 | Sorts reviews before skipping 50,000 rows | Covering descending timestamp index; OFFSET still scans past the skipped rows. | 3.004 | +81.94% | Yes · 25 rows |
| R23 | 0.024 | Unique Plus Code lookup | Keep the existing unique constraint. | 0.021 | +12.50% | Yes · 1 row |
| R24 | 4.815 | Same-name join and coordinate filters | Keep the original; trial index did not improve its plan. | 4.473 | +7.10% | Yes · 42 rows |
| R25 | 27.972 | All readings contribute to the safety percentages | Keep the original; a selective index cannot skip contributing rows. | 25.283 | +9.61% | Yes · 3 rows |
| W01 | 0.698 | Single trip insert with foreign-key checks | Unchanged insert; new trip indexes add maintenance. | 0.516 | +26.07% | Yes · 1 affected |
| W02 | 0.554 | Insert uses a unique conflict target | Unchanged insert; the moderation index adds maintenance. | 0.465 | +16.06% | Yes · 1 affected |
| W03 | 0.583 | Single save insert with existing conflict handling | No changes to SQL or saved-place indexes. | 0.484 | +16.98% | Yes · 1 affected |
| W04 | 33.727 | Aggregates all reviews; updates changed cached ratings | Unchanged update; covering indexes do not replace the aggregation. | 29.667 | +12.04% | Yes · 558 affected |
| W05 | 2.161 | Deletes 11,339 of 12,000 incident rows | Keep the scan; the filter is not selective on this seed. | 1.926 | +10.87% | Yes · 11339 affected |

Positive percentages are faster. Negative percentages are slower in these three runs. Treat sub-millisecond differences as noise-sensitive.

## Result verification

Reads were checked for matching rows, including duplicates, and for the requested sort order. Writes were compared using `RETURNING *` in separate transactions and rolled back.

| Check | Result |
|---|---|
| 28 of 30 statements | Matching rows and specified sort keys. |
| R04 · Tied top 30 | SQL unchanged. Three IDs differed; both sets contain 30 of the 34 eligible restaurants tied at 5.0. Exact IDs would require a secondary sort key. |
| R13 · NULL bug | Original `NOT IN` returned zero rows because the origin list contains NULLs. `NOT EXISTS` returned 33,368 places, matching an independent left anti-join. |
| R19 · Zero-trip hospitals | All 1,067 hospitals remained, including 19 with zero trips and a NULL latest-trip timestamp. |

## Plans for the five largest absolute time savings

These excerpts show selected nodes from run 1. See the raw plans for full costs, buffer counts and all three runs.

<details>
<summary>R19: 13620.371 → 3.932 ms average</summary>

Before:

```text
Sort  (cost=14196756.17..14196759.37 rows=1283 width=40) (actual time=13535.942..13535.970 rows=1067.00 loops=1)
Sort Key: ((SubPlan 1)) DESC
Sort Method: quicksort  Memory: 115kB
->  Seq Scan on place_categories  (cost=0.00..1.15 rows=1 width=4) (actual time=0.007..0.007 rows=1.00 loops=1)
->  Seq Scan on places p  (cost=0.00..14196688.78 rows=1283 width=40) (actual time=13.899..13535.174 rows=1067.00 loops=1)
->  Aggregate  (cost=5532.02..5532.03 rows=1 width=8) (actual time=6.330..6.330 rows=1.00 loops=1067)
->  Seq Scan on navigation_sessions n  (cost=0.00..5532.00 rows=6 width=0) (actual time=1.438..6.327 rows=5.09 loops=1067)
->  Aggregate  (cost=5532.02..5532.03 rows=1 width=8) (actual time=6.349..6.349 rows=1.00 loops=1067)
->  Seq Scan on navigation_sessions n_1  (cost=0.00..5532.00 rows=6 width=8) (actual time=1.436..6.345 rows=5.09 loops=1067)
Execution Time: 13536.062 ms
```

After:

```text
Sort  (cost=12648.18..12651.40 rows=1290 width=40) (actual time=3.540..3.560 rows=1067.00 loops=1)
Sort Key: (count(*)) DESC
Sort Method: quicksort  Memory: 115kB
->  Seq Scan on place_categories  (cost=0.00..1.15 rows=1 width=4) (actual time=0.002..0.003 rows=1.00 loops=1)
->  Nested Loop  (cost=8.55..12580.38 rows=1290 width=40) (actual time=0.045..3.465 rows=1067.00 loops=1)
->  Seq Scan on places p  (cost=0.00..1518.63 rows=1290 width=24) (actual time=0.010..1.886 rows=1067.00 loops=1)
->  Aggregate  (cost=8.55..8.56 rows=1 width=16) (actual time=0.001..0.001 rows=1.00 loops=1067)
->  Index Only Scan using cp3_nav_destination_started on navigation_sessions n  (cost=0.42..8.53 rows=6 width=8) (actual time=0.001..0.001 rows=5.09 loops=1067)
Index Cond: (dest_place_id = p.place_id)
Execution Time: 3.611 ms
```

</details>

<details>
<summary>R22: 16.636 → 3.004 ms average</summary>

Before:

```text
Limit  (cost=9339.48..9339.54 rows=25 width=22) (actual time=15.842..15.844 rows=25.00 loops=1)
->  Sort  (cost=9214.48..9439.47 rows=89998 width=22) (actual time=13.655..14.966 rows=50025.00 loops=1)
Sort Key: created_at DESC
Sort Method: external merge  Disk: 3000kB
->  Seq Scan on place_reviews  (cost=0.00..1739.98 rows=89998 width=22) (actual time=0.004..4.553 rows=89998.00 loops=1)
Execution Time: 16.730 ms
```

After:

```text
Limit  (cost=1772.69..1773.57 rows=25 width=22) (actual time=3.289..3.291 rows=25.00 loops=1)
->  Index Only Scan using cp3_reviews_moderation on place_reviews  (cost=0.42..3190.43 rows=89998 width=22) (actual time=0.028..2.452 rows=50025.00 loops=1)
Execution Time: 3.305 ms
```

</details>

<details>
<summary>R16: 13.298 → 3.875 ms average</summary>

Before:

```text
Sort  (cost=7114.98..7117.91 rows=1172 width=32) (actual time=12.969..12.986 rows=895.00 loops=1)
Sort Key: (count(*)) DESC
Sort Method: quicksort  Memory: 70kB
->  HashAggregate  (cost=7043.52..7055.24 rows=1172 width=32) (actual time=12.873..12.915 rows=895.00 loops=1)
->  Hash Join  (cost=1327.07..7033.78 rows=1948 width=24) (actual time=7.633..12.721 rows=1986.00 loops=1)
->  Seq Scan on navigation_sessions n  (cost=0.00..5532.00 rows=66547 width=4) (actual time=5.113..8.363 rows=66300.00 loops=1)
->  Seq Scan on places p  (cost=0.00..1312.42 rows=1172 width=24) (actual time=0.007..2.437 rows=1167.00 loops=1)
Execution Time: 13.041 ms
```

After:

```text
Sort  (cost=4683.54..4686.53 rows=1196 width=32) (actual time=3.862..3.877 rows=895.00 loops=1)
Sort Key: (count(*)) DESC
Sort Method: quicksort  Memory: 70kB
->  HashAggregate  (cost=4610.44..4622.40 rows=1196 width=32) (actual time=3.771..3.810 rows=895.00 loops=1)
->  Nested Loop  (cost=0.42..4600.50 rows=1989 width=24) (actual time=0.008..3.639 rows=1986.00 loops=1)
->  Seq Scan on places p  (cost=0.00..1318.42 rows=1196 width=24) (actual time=0.003..2.302 rows=1167.00 loops=1)
->  Index Only Scan using cp3_nav_destination_started on navigation_sessions n  (cost=0.42..2.72 rows=2 width=4) (actual time=0.001..0.001 rows=1.70 loops=1167)
Index Cond: ((dest_place_id = p.place_id) AND (started_at >= '2026-01-01 00:00:00+05:30'::timestamp with time zone))
Execution Time: 3.925 ms
```

</details>

<details>
<summary>R20: 10.185 → 1.369 ms average</summary>

Before:

```text
WindowAgg  (cost=6413.61..6559.94 rows=1000 width=44) (actual time=8.885..10.225 rows=30.00 loops=1)
->  GroupAggregate  (cost=6413.47..6544.94 rows=1000 width=12) (actual time=8.846..10.203 rows=30.00 loops=1)
->  Sort  (cost=5413.46..5414.93 rows=588 width=4) (actual time=7.765..7.870 rows=5494.50 loops=2)
Sort Key: ((navigation_sessions.started_at)::date)
Sort Method: quicksort  Memory: 193kB
Worker 0:  Sort Method: quicksort  Memory: 193kB
->  Parallel Seq Scan on navigation_sessions  (cost=0.00..5386.41 rows=588 width=4) (actual time=6.844..7.628 rows=5494.50 loops=2)
Execution Time: 10.266 ms
```

After:

```text
WindowAgg  (cost=1080.99..1471.21 rows=11150 width=44) (actual time=0.943..1.338 rows=30.00 loops=1)
->  GroupAggregate  (cost=1080.96..1303.96 rows=11150 width=12) (actual time=0.922..1.323 rows=30.00 loops=1)
->  Sort  (cost=1080.96..1108.83 rows=11150 width=4) (actual time=0.905..1.087 rows=10989.00 loops=1)
Sort Key: ((navigation_sessions.started_at)::date)
Sort Method: quicksort  Memory: 385kB
->  Index Only Scan using cp3_nav_june_started on navigation_sessions  (cost=0.29..331.41 rows=11150 width=4) (actual time=0.040..0.671 rows=10989.00 loops=1)
Execution Time: 1.368 ms
```

</details>

<details>
<summary>R15: 30.522 → 23.182 ms average</summary>

Before:

```text
Sort  (cost=8425.66..8525.75 rows=40036 width=53) (actual time=30.473..30.483 rows=558.00 loops=1)
Sort Key: p.place_id
Sort Method: quicksort  Memory: 51kB
->  HashAggregate  (cost=4464.18..5365.11 rows=40036 width=53) (actual time=25.434..30.416 rows=558.00 loops=1)
->  Hash Join  (cost=1812.95..3789.19 rows=89998 width=15) (actual time=4.919..16.096 rows=89998.00 loops=1)
->  Seq Scan on place_reviews r  (cost=0.00..1739.98 rows=89998 width=6) (actual time=0.004..2.859 rows=89998.00 loops=1)
->  Seq Scan on places p  (cost=0.00..1312.42 rows=40042 width=13) (actual time=0.002..2.892 rows=40042.00 loops=1)
Execution Time: 30.613 ms
```

After:

```text
Sort  (cost=7069.67..7142.05 rows=28951 width=53) (actual time=23.235..23.246 rows=558.00 loops=1)
Sort Key: p.place_id
Sort Method: quicksort  Memory: 51kB
->  Hash Join  (cost=3500.67..4924.21 rows=28951 width=53) (actual time=17.506..23.196 rows=558.00 loops=1)
Join Filter: ((p.review_count <> a.actual_reviews) OR (p.avg_rating <> a.actual_rating))
Rows Removed by Join Filter: 33873
->  Seq Scan on places p  (cost=0.00..1318.42 rows=40042 width=13) (actual time=0.003..1.487 rows=40042.00 loops=1)
->  Subquery Scan on a  (cost=2414.97..3138.77 rows=28952 width=44) (actual time=10.290..15.690 rows=34431.00 loops=1)
->  HashAggregate  (cost=2414.97..2849.25 rows=28952 width=44) (actual time=10.289..14.448 rows=34431.00 loops=1)
->  Seq Scan on place_reviews  (cost=0.00..1739.98 rows=89998 width=6) (actual time=0.002..2.151 rows=89998.00 loops=1)
Execution Time: 23.327 ms
```

</details>

## Write overhead and index storage

| Write | Before (ms) | After (ms) | Change (ms) |
|---|---:|---:|---:|
| W01 | 0.698 | 0.516 | -0.182 |
| W02 | 0.554 | 0.465 | -0.089 |
| W03 | 0.583 | 0.484 | -0.099 |
| W04 | 33.727 | 29.667 | -4.060 |
| W05 | 2.161 | 1.926 | -0.235 |

W01 and W02 maintain additional indexes. W03 has no new target-table indexes. W04 and W05 touch indexed tables, but their changes in these runs also reflect aggregation and delete costs; three runs do not isolate index maintenance. The observed insert latencies are small in absolute terms on this seed. Recheck write cost on the larger dataset before using this index set for a write-heavy workload.

Sizes are from `pg_relation_size` and exclude other indexes and TOAST data from the table column.

| Index | Table | Index (MiB) | Table (MiB) |
|---|---|---:|---:|
| `cp3_incidents_reported_at` | `incident_reports` | 0.27 | 0.89 |
| `cp3_nav_destination_started` | `navigation_sessions` | 6.04 | 23.69 |
| `cp3_nav_june_started` | `navigation_sessions` | 0.26 | 23.69 |
| `cp3_nav_origin_place` | `navigation_sessions` | 0.17 | 23.69 |
| `cp3_places_nearby` | `places` | 1.55 | 7.54 |
| `cp3_reviews_moderation` | `place_reviews` | 3.50 | 6.56 |
| `cp3_traffic_alert_time` | `traffic_readings` | 0.92 | 14.50 |

The June-only index is specific to this reporting workload. A production dashboard with a rolling date window would need a broader design. R02 and R23 already had efficient point lookups. R17, R18 and R25 still need a broad scan or a maintained summary, and W05 deletes about 95% of incident rows, so an extra expiry index was not justified.
