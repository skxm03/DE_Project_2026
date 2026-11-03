# Google Maps Navigation Database: DBMS Project

**Course:** Database Management Systems · **Year:** B.Tech 2nd year · **Team size:** 4
**Database:** PostgreSQL 15 or newer · **Final submission:** Mon 23 Nov 2026
**Topics used:** Data types & constraints · Keys & relationships · Normalization · Query execution plans · Indexing · Query optimization · VACUUM/ANALYZE · Partitioning & sharding

## Files in this folder

| Path                          | What it is                                                                                           |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| `README.md`                   | This project brief                                                                                   |
| `seed_data.zip`               | 11 CSV files (200,000 navigation sessions): the only input for Phase 2. Unzip it to get `seed_data/` |
| `queries/workload_30.sql`     | The 30 queries for Phase 3 (do not edit)                                                             |
| `benchmarks/run_benchmark.sh` | Timing script: 3 runs per query, average, raw plans saved                                            |
| `CHECKPOINTS.md`              | Checkpoint dates and the files each one needs (DE and AP repos)                                      |

**Getting started:** **clone this repository and push it into your team's DE repo** (the DE repo you submitted in the form); the steps are in [`CHECKPOINTS.md`](CHECKPOINTS.md). Keep the structure shown in [Repository structure](#repository-structure-submit-exactly-this). Unzip `seed_data.zip` inside your project folder, but don't commit the CSV files. Deadlines are in [`CHECKPOINTS.md`](CHECKPOINTS.md). Then begin with Phase 1.

---

## Team details (fill in before you start)

| Role       | Name           | Enrollment No. | GitHub Username  |
| ---------- | -------------- | -------------- | ---------------- |
| Group Lead | Saksham Saini  | 2501010397     | skxm03           |
| Member 2   | Nimit Sharma   | 2501010306     | ABUDIYAAAA       |
| Member 3   | Arpit Tripathi | 2501010085     | arpittripathi755 |
| Member 4   | Gurmehar Singh | 2501010171     | Gurmehar-git     |

**Team No.:** T0110 · **Section:** D · **Repository URL:** https://github.com/skxm03/DE_Project_2026

---

## How this project works

| Phase | What you do                                                                         | You submit                                                                                                              | Counts toward     |  Marks |
| ----- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------- | -----: |
| 1     | Understand the problem statements                                                   | `docs/01_problem_understanding.md`                                                                                      | Query Execution   |      2 |
| 2     | Work out the database schema **from the seed data** and load it                     | `sql/01_schema.sql`, `sql/02_load_data.sql`, `docs/02_schema_design.md`                                                 | Query Execution   |      5 |
| 3     | Run the **30 given SQL queries** and record their execution time                    | `docs/03_baseline_timings.md`, `benchmarks/results/baseline/`                                                           | Query Execution   |      3 |
| 4     | Optimize the queries and record the new times                                       | `sql/05_indexes.sql`, `sql/06_optimized_queries.sql`, `docs/04_optimization_report.md`, `benchmarks/results/optimized/` | Code Optimization |     16 |
| 5     | Scalability test on the **large dataset** (given later by faculty) and final report | `docs/05_scalability_report.md`, `benchmarks/results/large/`                                                            | Code Optimization |     14 |
|       | **Total**                                                                           |                                                                                                                         |                   | **40** |

---

## Phase 1: Problem statements

Google Maps knows millions of **places** (restaurants, hospitals, ATMs, petrol pumps …) with coordinates, a **Plus Code**, weekly **opening hours** (some open past midnight, some 24 hours) and user **reviews**. Roads are split into **segments** that report live **traffic** speeds; users report **incidents** like accidents and waterlogging. People search for places, save them to lists, and start **navigation sessions** in different travel modes—either from a known place or from their current GPS location. You have joined the Google Maps India data team.

The current database was put together quickly by an earlier team. It has **no documented schema** (only data exports survive), and the product teams are complaining:

| #   | Problem reported                                                                                                         | Team                  | Related queries         |
| --- | ------------------------------------------------------------------------------------------------------------------------ | --------------------- | ----------------------- |
| P1  | "**"Near me" and "open now"** searches are too slow—especially for places that close after midnight."                    | Search                | R01, R03, R04, R23      |
| P2  | "**Place pages** (details, hours, newest reviews) and the **Saved** tab lag."                                            | Places                | R02, R05, R06, W02, W03 |
| P3  | "The **live traffic** and **incident** layers must refresh every minute."                                                | Traffic               | R07, R08, R10, W05      |
| P4  | "**"Typical traffic"** charts and road-safety reports are slow."                                                         | Traffic               | R09, R25                |
| P5  | "The **routing team** needs ETA accuracy, re-routing hotspots and trend reports; starting navigation must be instant."   | Routing / ETA         | R11, R12, R17, R18, W01 |
| P6  | "The data team's "**places never used as a start point**" list is **empty**, which is impossible."                       | Data team             | R13                     |
| P7  | "**Data quality** checks (stale ratings, closed places still navigated to, missing hours, duplicate listings) time out." | Data quality          | R15, R16, R21, R24, W04 |
| P8  | "Leaderboards, moderation and health reports are slow, and navigation volume will grow **20×**."                         | Community / Analytics | R14, R19, R20, R22      |

**Your job:**

1. Rebuild a correct, well-constrained schema from the data exports (Phase 2).
2. Measure how the 30 most important queries perform today (Phase 3).
3. Make them fast **without changing their results** (Phase 4).
4. Prove the database will survive next year's growth (Phase 5).

**Deliverable for Phase 1** (`docs/01_problem_understanding.md`, at most 1 page):

- For each problem P1–P8, write in your own words what the business needs and which **stakeholder** is affected (traveller/driver, Local Guide, business owner, search, routing & ETA team, traffic team, data-quality team, moderation).
- Classify each problem as **customer-facing / real-time** or **reporting / analytics**. This decides your performance targets later.
- List any assumptions you make.

---

## Phase 2: Work out the schema from the seed data

You receive **`seed_data.zip`**. Unzip it to get a folder **`seed_data/`** with 11 CSV files, a real export of the production data:

| File                      |    Rows | What it contains                                      |
| ------------------------- | ------: | ----------------------------------------------------- |
| `cities.csv`              |      10 | Cities and their centre coordinates                   |
| `place_categories.csv`    |      12 | Place categories                                      |
| `places.csv`              |  40,042 | Places (points of interest)                           |
| `opening_hours.csv`       | 252,266 | Opening hours of each place per weekday               |
| `users.csv`               |  40,000 | Google Maps users (some are Local Guides)             |
| `place_reviews.csv`       |  89,998 | Reviews of places                                     |
| `saved_places.csv`        |  50,000 | Places saved by users into lists                      |
| `road_segments.csv`       |   2,000 | Road segments                                         |
| `traffic_readings.csv`    | 250,000 | Live traffic speed readings per segment               |
| `navigation_sessions.csv` | 200,000 | Every navigation from 1 Jan 2025 to 30 Jun 2026       |
| `incident_reports.csv`    |  12,000 | Accidents, roadwork, waterlogging … reported by users |

The first line of every file is the header (column names). Here are the headers and the first rows of each file:

**cities.csv**

```
city_id,city_name,center_lat,center_lng
1,Bengaluru,12.971600,77.594600
2,Mumbai,19.076000,72.877700
```

**place_categories.csv**

```
category_id,category_name
1,Restaurant
2,Cafe
```

**places.csv**

```
place_id,plus_code,name,category_id,city_id,latitude,longitude,address,phone,website,price_level,avg_rating,review_count,is_permanently_closed,created_at
1,22222222+23,Udupi Bhavan 1,1,2,19.065341,72.983234,"2, Main Road, Mumbai 400001",+918000000001,https://www.udupibhavan1.in,2,3.5,78,f,2020-01-30 04:57:52+05:30
2,22222222+24,City Care Hospital 2,3,4,17.267136,78.384980,"3, Ring Road, Hyderabad 500002",+918000000002,https://www.citycarehospital2.in,,3.6,43,f,2019-03-11 09:19:24+05:30
```

**opening_hours.csv**

```
place_id,weekday,opens,closes
1,1,11:00:00,23:00:00
1,2,11:00:00,23:00:00
```

**users.csv**

```
user_id,display_name,email,home_city_id,is_local_guide,guide_level,created_at
1,Vivaan S.,vivaan.sharma1@gmail.com,3,f,,2023-12-19 08:40:05+05:30
2,Aditya S.,aditya.sharma2@gmail.com,8,f,,2018-05-16 23:42:52+05:30
```

**place_reviews.csv**

```
review_id,place_id,user_id,rating,review_text,photo_count,created_at
1,29646,22193,4,ATM was out of cash,3,2020-01-01 00:10:36+05:30
2,9572,23965,5,Clean and well maintained,0,2020-01-01 00:25:18+05:30
```

**saved_places.csv**

```
user_id,place_id,list_name,saved_at
1,453,Want to go,2022-12-03 00:30:42+05:30
1,1678,Starred,2026-02-13 16:08:18+05:30
```

**road_segments.csv**

```
segment_id,road_name,city_id,road_type,start_lat,start_lng,end_lat,end_lng,length_m,speed_limit_kmph
1,MG Road (Segment 2),1,ARTERIAL,12.868853,77.636625,12.867385,77.631984,1650,50
2,Hosur Road (Segment 3),1,ARTERIAL,13.013430,77.539792,13.017427,77.541674,1506,50
```

**traffic_readings.csv**

```
reading_id,segment_id,recorded_at,avg_speed_kmph,congestion_level
1,454,2025-01-01 00:00:00+05:30,29.5,LOW
2,236,2025-01-01 00:03:00+05:30,54.9,LOW
```

**navigation_sessions.csv**

```
session_id,user_id,origin_place_id,origin_lat,origin_lng,dest_place_id,travel_mode,started_at,distance_km,eta_minutes,actual_minutes,rerouted_count,status
1,5997,,18.536584,73.917604,27324,DRIVE,2025-01-01 00:00:00+05:30,13.25,40,37,0,COMPLETED
2,,,19.051149,72.753160,25251,TRANSIT,2025-01-01 00:03:55+05:30,10.63,35,37,0,COMPLETED
```

**incident_reports.csv**

```
report_id,segment_id,user_id,incident_type,reported_at,expires_at,upvotes
1,79,35594,ROADWORK,2025-01-01 00:00:00+05:30,2025-01-01 06:00:00+05:30,24
2,35,14996,POLICE,2025-01-01 01:05:00+05:30,2025-01-01 06:05:00+05:30,1
```

Open the files yourself (a spreadsheet, `head`, or `SELECT` after a quick load into a scratch table) and study the data carefully. **Nobody will give you the CREATE TABLE statements.** Working them out _is_ the task.

### 2.1 What you must identify (for every table)

1. **Table name and column names.** Use exactly the file names and CSV headers. The 30 queries depend on them.
2. **Data type** of every column. Choose the _right_ type, not just `TEXT` everywhere. Think about money, timestamps with a time-zone offset, yes/no columns, small whole numbers, decimals and short codes.
3. **Primary key.** Is it one column, or a combination? (Look closely at `opening_hours`, `saved_places` and `traffic_readings`. Is the Plus Code a candidate key?)
4. **Foreign keys.** Which column points to which table? What should happen **ON DELETE** (CASCADE, RESTRICT or SET NULL), and why?
5. **NOT NULL vs NULL.** Some columns are empty in some rows. Find out **when** and **why**, and decide which columns must never be empty. Why do some navigation sessions have no `origin_place_id` or no `user_id`? When are `actual_minutes`, `price_level`, `guide_level`, `phone` and `website` empty?
6. **UNIQUE** columns (natural candidate keys such as emails, phone numbers, codes and handles).
7. **CHECK constraints.** Write at least **12** that the data obeys and the business needs. Look for formats (Plus Code), coordinate ranges, allowed values (categories, modes, statuses, congestion levels, incident types, list names), weekday numbers, the meaning of `closes` < `opens`, and rules tying columns together (completed ⇔ actual time known, a Local Guide has a level, an incident expires after it was reported).
8. **Relationships and cardinalities** (1:1, 1:N, M:N). Draw the **ER diagram** (image + Mermaid code).
9. **Normal form.** Show that each table is in 3NF/BCNF (list its functional dependencies). Point out any column that is _derived or redundant_ (hint: `places.avg_rating`/`review_count` vs `place_reviews`; `traffic_readings.congestion_level` vs speed and the segment's limit; `eta_minutes` vs distance and mode) and say whether keeping it is justified.

### 2.2 Rules for your schema

- Create every table in a schema named **`gmaps`**: `CREATE SCHEMA gmaps;` and `SET search_path TO gmaps;`
- In this phase create **only constraints**: PK, FK, UNIQUE, NOT NULL, CHECK. **Do not create any other index yet.** (PostgreSQL automatically indexes PRIMARY KEY and UNIQUE columns; that's allowed. Note which indexes exist.) Your baseline in Phase 3 must reflect a database _without_ tuning.
- Your constraints must accept **all** rows of the seed data. If a load fails, either your constraint is wrong or you found a data problem. Explain which in your design doc.

### 2.3 Load the data

Write `sql/02_load_data.sql` using `\copy`, loading tables in the right order (parents before children):

```sql
SET search_path TO gmaps;
\copy cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true)
-- ... the other tables, in an order that satisfies your foreign keys
ANALYZE;
```

Then verify the row counts match the table above, and run at least **3 integrity checks** of your own (e.g. "a session's origin place and destination are in the same city", "the stored rating equals the average of the reviews", "every navigation's origin coordinates match its origin place when one is set"). Paste the results into `docs/02_schema_design.md`.

### Phase 2 deliverables

- `sql/01_schema.sql`: runs top-to-bottom on an empty database without errors
- `sql/02_load_data.sql`: loads all 11 files without errors
- `docs/02_schema_design.md`: data dictionary (table · column · type · constraint · _why_), ER diagram, FDs and normal form per table, integrity-check results, and every data problem you found

---

## Phase 3: Run the 30 queries and record the time

The file **`queries/workload_30.sql`** contains **30 queries**: 25 reads (`R01`–`R25`) and 5 writes (`W01`–`W05`). They're also listed in the [Appendix](#appendix-the-30-queries). **Do not modify them.** If a query fails, your schema doesn't match the seed data; fix the schema, not the query.

### 3.1 How to measure (everyone must use the same method)

- Run each query with `EXPLAIN (ANALYZE, BUFFERS)` and read the **`Execution Time`** at the bottom.
- Run each query **3 times** and record the **average** of the three `Execution Time` values. Keep all three runs in the raw plan file.
- Write queries (`W01`–`W05`) must be measured inside `BEGIN; … ROLLBACK;` so the data does not change.
- Close other heavy applications while measuring, and use the **same laptop** for Phase 3 and Phase 4.

The helper script does all of this for you:

```bash
./benchmarks/run_benchmark.sh <your_database> baseline
# → benchmarks/results/baseline/summary.csv   (avg, median, min, max, scan types)
# → benchmarks/results/baseline/R01.txt …     (full plans of all 3 runs)
```

> ⚠️ One of the 30 queries takes **several seconds** on the seed data. That's intentional. Let it finish, and don't skip it.

### 3.2 Deliverable: the timing table

In `docs/03_baseline_timings.md`, fill this table for **all 30** queries:

| SQL Query                                                                                                  | Type  | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
| ---------------------------------------------------------------------------------------------------------- | ----- | ---------: | ---------: | ---------: | -----------: |
| R01: "Restaurants near me": open restaurants within ~1 km of Koramangala (12.9352, 77.6245), nearest first | READ  |            |            |            |              |
| R02: Place page: details of place 18 with Tuesday's opening hours                                          | READ  |            |            |            |              |
| R03: Search: Bengaluru places with "biryani" in the name, best rated first                                 | READ  |            |            |            |              |
| R04: "Open now" filter: Bengaluru restaurants open at 23:30 on a Saturday (some close after midnight)      | READ  |            |            |            |              |
| R05: Place page: the 10 newest reviews of place 18                                                         | READ  |            |            |            |              |
| R06: "Saved" tab: user 1005's saved places grouped by list                                                 | READ  |            |            |            |              |
| R07: Live traffic layer: the latest reading of every Outer Ring Road segment in Bengaluru                  | READ  |            |            |            |              |
| R08: Traffic alerts: Bengaluru segments with heavy traffic or standstill since 18:00 on 30 June 2026       | READ  |            |            |            |              |
| R09: "Typical traffic" chart: average speed by hour of the day on segment 5                                | READ  |            |            |            |              |
| R10: Incident layer: incidents reported in Bengaluru on 30 June 2026                                       | READ  |            |            |            |              |
| R11: ETA quality: average error (actual − ETA, minutes) per travel mode per month in 2026                  | READ  |            |            |            |              |
| R12: Trends: 10 most-navigated-to places in Mumbai in the last 7 days of June 2026                         | READ  |            |            |            |              |
| R13: Data team: places that have never been the starting point of a navigation                             | READ  |            |            |            |              |
| R14: Local Guides leaderboard: users with the most reviews in 2026 (photos as tie-breaker)                 | READ  |            |            |            |              |
| R15: Data quality: places whose stored rating or review count no longer matches their reviews              | READ  |            |            |            |              |
| R16: Data quality: permanently closed places that people still navigate to (2026)                          | READ  |            |            |            |              |
| R17: Routing team: destinations with the most re-routing on average (at least 5 trips)                     | READ  |            |            |            |              |
| R18: Product analytics: share of cancelled navigations per travel mode                                     | READ  |            |            |            |              |
| R19: Health report: every Bengaluru hospital with its number of navigations and the most recent one        | READ  |            |            |            |              |
| R20: Product analytics: navigations per day and running total for June 2026                                | READ  |            |            |            |              |
| R21: Data team: places with no opening hours, counted per category                                         | READ  |            |            |            |              |
| R22: Moderation console: all reviews, newest first, page 2,001 (25 per page)                               | READ  |            |            |            |              |
| R23: Plus Code search: open the place with this code                                                       | READ  |            |            |            |              |
| R24: Duplicate listings: Bengaluru restaurants with the same name within ~100 m of each other              | READ  |            |            |            |              |
| R25: Road safety: share of readings above the speed limit, per road type                                   | READ  |            |            |            |              |
| W01: "Start": begin navigation from current location to place 18                                           | WRITE |            |            |            |              |
| W02: Write a review: user 1005 rates place 18                                                              | WRITE |            |            |            |              |
| W03: "Save": user 1005 adds place 18 to "Want to go"                                                       | WRITE |            |            |            |              |
| W04: Nightly job: recompute every place's rating and review count                                          | WRITE |            |            |            |              |
| W05: Housekeeping: delete incident reports that expired before June 2026                                   | WRITE |            |            |            |              |
| **Total (sum of all 30)**                                                                                  |       |            |            |            |              |

Below the table, add for each query the **scan type** from the plan (Seq Scan, Index Scan, …) and one line on **why** it is slow or fast.

---

## Phase 4: Optimize the queries

Make the queries faster. **The results must stay the same** (same rows; order matters only where the query has an `ORDER BY`).

### 4.1 Techniques you may use

| Technique                         | Example                                                                                                                                                                                                           |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B-tree index (single / composite) | the right column **order** matters: equality columns first, then range/sort                                                                                                                                       |
| Partial index                     | index only the rows a query needs (e.g. a rare status)                                                                                                                                                            |
| Covering index                    | `INCLUDE (...)` so the table is never visited (Index Only Scan)                                                                                                                                                   |
| Expression index                  | index the exact expression used in `WHERE`                                                                                                                                                                        |
| GIN index                         | for `ILIKE '%text%'` (extension `pg_trgm`), arrays or full-text search                                                                                                                                            |
| BRIN index                        | for huge tables stored in time order                                                                                                                                                                              |
| Query rewrite                     | sargable date ranges instead of functions on columns; `NOT EXISTS` instead of `NOT IN`; joins instead of correlated subqueries; keyset instead of `OFFSET` pagination; `UNION ALL` instead of `OR` across columns |
| VACUUM / ANALYZE                  | fresh statistics and visibility maps                                                                                                                                                                              |
| Summary table / materialized view | for heavy reports that don't need live data (state how it's refreshed)                                                                                                                                            |

**Not allowed:** changing the data, deleting rows, changing PostgreSQL server settings to hide the problem (e.g. huge `work_mem`, `enable_seqscan = off`), or caching results outside the database.

### 4.2 How to work

1. Put every index in `sql/05_indexes.sql`, each with a comment: **which queries it serves and why this type and column order**.
2. Put rewritten queries in `sql/06_optimized_queries.sql`. Copy `queries/workload_30.sql` and change **only** the queries you rewrite, keeping the `-- @R01` markers.
3. **Prove the results are unchanged** for every rewritten query (compare row counts, plus a checksum or an `EXCEPT` query). Put the proof in your report.
4. Benchmark again with the same method:

```bash
./benchmarks/run_benchmark.sh <your_database> optimized 5 sql/06_optimized_queries.sql
```

> 🔎 **Read the results, not just the timings.** At least one of the 30 original queries returns a **wrong answer** because of a subtle SQL rule about NULLs. Find it, explain it, and fix it. This is worth marks.

### 4.3 Deliverable: the optimization table

In `docs/04_optimization_report.md`:

| Query      | Before (ms) | Problem found in the plan                    | Optimization applied                                                          | After (ms) |    Improvement | Same result? |
| ---------- | ----------: | -------------------------------------------- | ----------------------------------------------------------------------------- | ---------: | -------------: | :----------: |
| R01        |             | e.g. Seq Scan on 40k places + acos() per row | e.g. index on `places(category_id, latitude, longitude)` for the bounding box |            | e.g. 98% (60×) |      ✅      |
| … all 30 … |             |                                              |                                                                               |            |                |              |
| **Total**  |             |                                              |                                                                               |            |                |              |

Improvement % = (before − after) / before × 100

Also include:

- **Before/after `EXPLAIN` plans** for your 5 biggest improvements
- **Write overhead:** which write queries got **slower** because of your indexes, by how much, and whether that's acceptable
- **Index storage:** the size of each index you created (`pg_relation_size`) compared with its table
- **Queries you could not speed up**, and why (an honest "this query must read most of the table" earns marks)

---

## Phase 5: Scalability report (large dataset round)

Your optimizations worked on 200,000 navigation sessions. Next year the business expects **20× the volume**.

By **Thu 19 Nov 2026**, faculty will release **`large_data.zip`**: the same 11 CSV files with about **20× the rows** (≈ 4,000,000 navigation sessions, ≈ 5,000,000 traffic readings, ≈ 5,045,000 opening hours, ≈ 801,000 places, ≈ 1,800,000 place reviews). Until then, work on the design part of the report.

### 5.1 What to do with the large dataset

1. Create a new database. Run **your** `01_schema.sql`, load `large_data/` with your load script (change the folder name only), then run **your** `05_indexes.sql` and `ANALYZE`.
2. Run your **optimized** queries (`sql/06_optimized_queries.sql`). **Do not run the original 30 on the large data.** Some of them could run for a very long time.
    - R22 pages with `OFFSET`; if you replaced it with keyset pagination, explain how the "last seen" value is chosen for the large data.
3. Record the times and compare with your Phase 4 results on the seed data.

| Query      | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
| ---------- | ---------------------: | ----------------------: | --------------------: | :-----------: | ------------------------ |
| R01        |                        |                         |                       |               |                          |
| … all 30 … |                        |                         |                       |               |                          |

### 5.2 Performance targets on the large dataset

| Query group                  | Queries                                                    | Target (average of 3 runs) |
| ---------------------------- | ---------------------------------------------------------- | -------------------------: |
| Real-time / user-facing      | R01, R02, R04, R05, R06, R07, R08, R10, R23, W01, W02, W03 |             **under 5 ms** |
| Interactive search and tools | R03, R09, R12, R13, R22, R24                               |           **under 250 ms** |
| Reports and analytics        | R11, R14, R15, R16, R17, R18, R19, R20, R21, R25           |         **under 5,000 ms** |
| Batch jobs                   | W04, W05                                                   |         **under 2,000 ms** |

If a query misses its target, **find out why from the plan and fix it.** A query that was fast on the seed data can become slow on large data for reasons that only appear at scale. Show the before/after plans for every fix.

### 5.3 Deliverable: `docs/05_scalability_report.md`

1. **Results table** (above), with every target met or explained.
2. **Growth analysis.** Group your queries by how their time grew when the data grew 20×:
    - _stayed about the same_ (why? e.g. index lookups grow with log n)
    - _grew about 20×_ (why? e.g. they read a fixed _share_ of the table)
    - _grew more than 20×_ (why, and what you did about it)
3. **What broke at scale** and how you fixed it (plans before/after).
4. **Storage:** total database size, table vs index size, on seed and large data.
5. **Architecture for 100×:** explain with numbers from your own measurements:
    - **Partitioning:** which table, by which column (RANGE / LIST / HASH), and why. Write the DDL for `navigation_sessions`, show partition pruning with `EXPLAIN`, and note the primary-key rule for partitioned tables.
    - **Sharding:** Would you shard by city/region (geography), by user, or by time? Think about "near me" searches and live traffic (local) vs a user's history (global). Which queries become cross-shard, and how would you handle them?
    - **Read replicas and caching:** which of the 30 queries you would send to a replica or cache, and which must hit the primary.
    - **Maintenance:** VACUUM/autovacuum settings for `navigation_sessions`, archiving old data, refreshing summary tables.
6. **Conclusion:** is your database ready for next year? What are the remaining risks?

---

## Repository structure (submit exactly this)

```
googlemaps-dbms-<team-no>/
├── README.md                          # team table, how to run, headline numbers
├── team.json                          # group lead, members, enrollment numbers
├── docs/
│   ├── 01_problem_understanding.md
│   ├── 02_schema_design.md
│   ├── 03_baseline_timings.md
│   ├── 04_optimization_report.md
│   └── 05_scalability_report.md
├── diagrams/
│   └── er_diagram.png
├── sql/
│   ├── 01_schema.sql
│   ├── 02_load_data.sql
│   ├── 05_indexes.sql
│   ├── 06_optimized_queries.sql
│   └── 08_partitioning.sql
├── queries/
│   └── workload_30.sql                # given; do not edit
└── benchmarks/
    ├── run_benchmark.sh               # given
    └── results/
        ├── baseline/                  # Phase 3: summary.csv + raw plans
        ├── optimized/                 # Phase 4
        └── large/                     # Phase 5
```

`team.json`:

```json
{
	"team_number": "",
	"group_lead": { "name": "", "enrollment_no": "", "github": "" },
	"members": [
		{ "name": "", "enrollment_no": "", "github": "" },
		{ "name": "", "enrollment_no": "", "github": "" },
		{ "name": "", "enrollment_no": "", "github": "" }
	],
	"postgres_version": "",
	"laptop_used_for_benchmarks": ""
}
```

**Do not commit the CSV files** (`seed_data/`, `large_data/`); add them to `.gitignore`. They are too large and we already have them.

---

## Timeline

| Due                      | Work                                                                      | Checkpoint                                                  |
| ------------------------ | ------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Tue 3 Nov 2026           | Clone this repo into your team's DE repo, add members, commit `team.json` | **CP0** Setup                                               |
| Mon 16 Nov 2026          | Phase 1 + Phase 2 (schema, load, ER, data dictionary)                     | **CP1** Schema loads all seed data with no errors           |
| Tue 17 Nov 2026          | Phase 3 (baseline, 3 runs, average) + start Phase 4                       | **CP2** Baseline table for all 30 queries committed         |
| Thu 19 Nov 2026          | Phase 4 (indexes, rewrites, wrong-result query)                           | **CP3** Optimization table committed                        |
| Mon 23 Nov 2026          | Phase 5 on the large dataset + final report                               | **CP4 Final submission:** last commit on the default branch |
| Wed 25 – Thu 26 Nov 2026 | Individual analysis, in class time                                        | **CP5** Individual analysis                                 |

Full list of files per checkpoint, including the AP repo: [`CHECKPOINTS.md`](CHECKPOINTS.md).

---

## Evaluation (40 marks)

These 40 marks are the DE part of the project: **Query Execution (10)** and **Code Optimization (30)**.
The AP project (20) and your Individual analysis (40) make up the rest of the 100.

| Phase | Criteria                                                                                                                                                                                                                  |  Marks |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -----: |
|       | **Query Execution**                                                                                                                                                                                                       | **10** |
| 1     | Problems understood, stakeholders and query groups correctly identified                                                                                                                                                   |      2 |
| 2     | Correct data types (1), keys and foreign keys with justified delete rules (1), ≥12 meaningful CHECK / NOT NULL / UNIQUE constraints (1), ER diagram + normal-form analysis (1), data loads cleanly + integrity checks (1) |      5 |
| 3     | All 30 queries measured with the required method: 3 runs, average (1), raw plans committed (1), scan type and reason for each query (1)                                                                                   |      3 |
|       | **Code Optimization**                                                                                                                                                                                                     | **30** |
| 4     | Speed-up achieved with appropriate techniques (6), every index justified (3), results proven unchanged (2), wrong-result query found and explained (2), write overhead and index storage reported (3)                     |     16 |
| 5     | Large-dataset results with all targets met or explained (4), growth analysis (3), scale-only problems found and fixed (3), partitioning DDL + sharding/replica design backed by your numbers (4)                          |     14 |
|       | **Total**                                                                                                                                                                                                                 | **40** |

**Integrity rules**

- Every number in your reports must match the raw plan files in `benchmarks/results/`. Copied or invented timings make the whole phase score 0.
- Every member must have commits; the commit history is checked.
- You may use AI tools to learn, but you must be able to explain every index and rewrite in your individual analysis.

---

## Appendix: the 30 queries

These are identical to `queries/workload_30.sql`. Use the file, not copy-paste from this page.

**R01: "Restaurants near me": open restaurants within ~1 km of Koramangala (12.9352, 77.6245), nearest first**

```sql
SELECT place_id, name, avg_rating,
       round((6371 * acos(least(1, cos(radians(12.9352)) * cos(radians(latitude)) * cos(radians(longitude) - radians(77.6245))
                                  + sin(radians(12.9352)) * sin(radians(latitude)))))::numeric, 3) AS km
FROM places
WHERE category_id = 1
  AND NOT is_permanently_closed
  AND latitude  BETWEEN 12.9352 - 0.009 AND 12.9352 + 0.009
  AND longitude BETWEEN 77.6245 - 0.0093 AND 77.6245 + 0.0093
ORDER BY km
LIMIT 20;
```

**R02: Place page: details of place 18 with Tuesday's opening hours**

```sql
SELECT p.place_id, p.name, p.address, p.phone, p.avg_rating, p.review_count, h.opens, h.closes
FROM places p
LEFT JOIN opening_hours h ON h.place_id = p.place_id AND h.weekday = 2
WHERE p.place_id = 18;
```

**R03: Search: Bengaluru places with "biryani" in the name, best rated first**

```sql
SELECT place_id, name, avg_rating, review_count
FROM places
WHERE city_id = 1 AND name ILIKE '%biryani%'
ORDER BY avg_rating DESC NULLS LAST, review_count DESC
LIMIT 20;
```

**R04: "Open now" filter: Bengaluru restaurants open at 23:30 on a Saturday (some close after midnight)**

```sql
SELECT p.place_id, p.name, h.opens, h.closes
FROM places p
JOIN opening_hours h ON h.place_id = p.place_id AND h.weekday = 6
WHERE p.city_id = 1 AND p.category_id = 1 AND NOT p.is_permanently_closed
  AND (   (h.opens < h.closes AND TIME '23:30' BETWEEN h.opens AND h.closes)
       OR (h.opens > h.closes AND (TIME '23:30' >= h.opens OR TIME '23:30' < h.closes)))
ORDER BY p.avg_rating DESC NULLS LAST
LIMIT 30;
```

**R05: Place page: the 10 newest reviews of place 18**

```sql
SELECT r.review_id, u.display_name, u.is_local_guide, r.rating, r.review_text, r.photo_count, r.created_at
FROM place_reviews r
JOIN users u ON u.user_id = r.user_id
WHERE r.place_id = 18
ORDER BY r.created_at DESC
LIMIT 10;
```

**R06: "Saved" tab: user 1005's saved places grouped by list**

```sql
SELECT s.list_name, p.place_id, p.name, s.saved_at
FROM saved_places s
JOIN places p ON p.place_id = s.place_id
WHERE s.user_id = 1005
ORDER BY s.list_name, s.saved_at DESC;
```

**R07: Live traffic layer: the latest reading of every Outer Ring Road segment in Bengaluru**

```sql
SELECT DISTINCT ON (t.segment_id) t.segment_id, s.road_name, t.recorded_at, t.avg_speed_kmph, t.congestion_level
FROM traffic_readings t
JOIN road_segments s ON s.segment_id = t.segment_id
WHERE s.city_id = 1 AND s.road_name LIKE 'Outer Ring Road%'
ORDER BY t.segment_id, t.recorded_at DESC;
```

**R08: Traffic alerts: Bengaluru segments with heavy traffic or standstill since 18:00 on 30 June 2026**

```sql
SELECT s.segment_id, s.road_name, t.recorded_at, t.avg_speed_kmph, t.congestion_level
FROM traffic_readings t
JOIN road_segments s ON s.segment_id = t.segment_id
WHERE s.city_id = 1
  AND t.congestion_level IN ('HEAVY', 'STANDSTILL')
  AND t.recorded_at >= '2026-06-30 18:00:00+05:30'
ORDER BY t.recorded_at DESC;
```

**R09: "Typical traffic" chart: average speed by hour of the day on segment 5**

```sql
SELECT EXTRACT(HOUR FROM recorded_at) AS hour, round(avg(avg_speed_kmph), 1) AS avg_speed, count(*) AS readings
FROM traffic_readings
WHERE segment_id = 5
GROUP BY 1
ORDER BY 1;
```

**R10: Incident layer: incidents reported in Bengaluru on 30 June 2026**

```sql
SELECT i.report_id, i.incident_type, s.road_name, i.reported_at, i.expires_at, i.upvotes
FROM incident_reports i
JOIN road_segments s ON s.segment_id = i.segment_id
WHERE s.city_id = 1
  AND DATE(i.reported_at) = '2026-06-30'
ORDER BY i.reported_at DESC;
```

**R11: ETA quality: average error (actual − ETA, minutes) per travel mode per month in 2026**

```sql
SELECT date_trunc('month', started_at) AS month, travel_mode,
       round(avg(actual_minutes - eta_minutes), 2) AS avg_error_min, count(*) AS trips
FROM navigation_sessions
WHERE status = 'COMPLETED'
  AND EXTRACT(YEAR FROM started_at) = 2026
GROUP BY 1, 2
ORDER BY 1, 2;
```

**R12: Trends: 10 most-navigated-to places in Mumbai in the last 7 days of June 2026**

```sql
SELECT p.place_id, p.name, count(*) AS navigations
FROM navigation_sessions n
JOIN places p ON p.place_id = n.dest_place_id
WHERE p.city_id = 2
  AND n.started_at >= '2026-06-24'
GROUP BY p.place_id, p.name
ORDER BY navigations DESC
LIMIT 10;
```

**R13: Data team: places that have never been the starting point of a navigation**

```sql
SELECT p.place_id, p.name
FROM places p
WHERE p.place_id NOT IN (SELECT n.origin_place_id FROM navigation_sessions n);
```

**R14: Local Guides leaderboard: users with the most reviews in 2026 (photos as tie-breaker)**

```sql
SELECT u.user_id, u.display_name, u.guide_level, count(*) AS reviews, sum(r.photo_count) AS photos
FROM place_reviews r
JOIN users u ON u.user_id = r.user_id
WHERE r.created_at >= '2026-01-01'
GROUP BY u.user_id, u.display_name, u.guide_level
ORDER BY reviews DESC, photos DESC
LIMIT 20;
```

**R15: Data quality: places whose stored rating or review count no longer matches their reviews**

```sql
SELECT p.place_id, p.avg_rating, p.review_count, round(avg(r.rating), 1) AS actual_rating, count(*) AS actual_reviews
FROM places p
JOIN place_reviews r ON r.place_id = p.place_id
GROUP BY p.place_id, p.avg_rating, p.review_count
HAVING p.review_count <> count(*) OR p.avg_rating <> round(avg(r.rating), 1)
ORDER BY p.place_id;
```

**R16: Data quality: permanently closed places that people still navigate to (2026)**

```sql
SELECT p.place_id, p.name, count(*) AS navigations_2026
FROM places p
JOIN navigation_sessions n ON n.dest_place_id = p.place_id
WHERE p.is_permanently_closed
  AND n.started_at >= '2026-01-01'
GROUP BY p.place_id, p.name
ORDER BY navigations_2026 DESC;
```

**R17: Routing team: destinations with the most re-routing on average (at least 5 trips)**

```sql
SELECT dest_place_id, count(*) AS trips, round(avg(rerouted_count), 2) AS avg_reroutes
FROM navigation_sessions
GROUP BY dest_place_id
HAVING count(*) >= 5
ORDER BY avg_reroutes DESC
LIMIT 20;
```

**R18: Product analytics: share of cancelled navigations per travel mode**

```sql
SELECT travel_mode, count(*) AS sessions,
       round(100.0 * count(*) FILTER (WHERE status = 'CANCELLED') / count(*), 1) AS cancelled_pct
FROM navigation_sessions
GROUP BY travel_mode
ORDER BY cancelled_pct DESC;
```

**R19: Health report: every Bengaluru hospital with its number of navigations and the most recent one**

```sql
SELECT p.place_id, p.name,
       (SELECT count(*) FROM navigation_sessions n WHERE n.dest_place_id = p.place_id) AS navigations,
       (SELECT max(n.started_at) FROM navigation_sessions n WHERE n.dest_place_id = p.place_id) AS last_navigation_at
FROM places p
WHERE p.category_id = (SELECT category_id FROM place_categories WHERE category_name = 'Hospital')
  AND p.city_id = 1
ORDER BY navigations DESC;
```

**R20: Product analytics: navigations per day and running total for June 2026**

```sql
SELECT day, sessions, sum(sessions) OVER (ORDER BY day) AS running_total
FROM (
    SELECT started_at::date AS day, count(*) AS sessions
    FROM navigation_sessions
    WHERE started_at::date BETWEEN '2026-06-01' AND '2026-06-30'
    GROUP BY 1
) d
ORDER BY day;
```

**R21: Data team: places with no opening hours, counted per category**

```sql
SELECT c.category_name, count(*) AS places_without_hours
FROM places p
JOIN place_categories c ON c.category_id = p.category_id
WHERE NOT EXISTS (SELECT 1 FROM opening_hours h WHERE h.place_id = p.place_id)
GROUP BY c.category_name
ORDER BY places_without_hours DESC;
```

**R22: Moderation console: all reviews, newest first, page 2,001 (25 per page)**

```sql
SELECT review_id, place_id, user_id, rating, created_at
FROM place_reviews
ORDER BY created_at DESC
OFFSET 50000
LIMIT 25;
```

**R23: Plus Code search: open the place with this code**

```sql
SELECT place_id, name, latitude, longitude
FROM places
WHERE plus_code = '22222222+2W';
```

**R24: Duplicate listings: Bengaluru restaurants with the same name within ~100 m of each other**

```sql
SELECT a.place_id, b.place_id AS duplicate_id, a.name
FROM places a
JOIN places b ON b.name = a.name AND b.place_id > a.place_id
             AND abs(b.latitude - a.latitude) < 0.001 AND abs(b.longitude - a.longitude) < 0.001
WHERE a.city_id = 1 AND a.category_id = 1;
```

**R25: Road safety: share of readings above the speed limit, per road type**

```sql
SELECT s.road_type, count(*) AS readings,
       round(100.0 * count(*) FILTER (WHERE t.avg_speed_kmph > s.speed_limit_kmph) / count(*), 1) AS over_limit_pct
FROM traffic_readings t
JOIN road_segments s ON s.segment_id = t.segment_id
GROUP BY s.road_type
ORDER BY over_limit_pct DESC;
```

**W01: "Start": begin navigation from current location to place 18**

```sql
INSERT INTO navigation_sessions (session_id, user_id, origin_lat, origin_lng, dest_place_id, travel_mode,
                                 started_at, distance_km, eta_minutes, status)
VALUES (90000001, 1005, 12.935200, 77.624500, 18, 'TWO_WHEELER', '2026-07-01 20:00:00+05:30', 4.20, 14, 'IN_PROGRESS');
```

**W02: Write a review: user 1005 rates place 18**

```sql
INSERT INTO place_reviews (review_id, place_id, user_id, rating, review_text, photo_count, created_at)
VALUES (90000001, 18, 1005, 4, 'Good food, slow service', 2, '2026-07-01 21:00:00+05:30')
ON CONFLICT (place_id, user_id) DO NOTHING;
```

**W03: "Save": user 1005 adds place 18 to "Want to go"**

```sql
INSERT INTO saved_places (user_id, place_id, list_name, saved_at)
VALUES (1005, 18, 'Want to go', '2026-07-01 21:05:00+05:30')
ON CONFLICT DO NOTHING;
```

**W04: Nightly job: recompute every place's rating and review count**

```sql
UPDATE places p
SET avg_rating = s.avg_rating, review_count = s.n
FROM (SELECT place_id, round(avg(rating), 1) AS avg_rating, count(*) AS n FROM place_reviews GROUP BY place_id) s
WHERE s.place_id = p.place_id
  AND (p.avg_rating IS DISTINCT FROM s.avg_rating OR p.review_count <> s.n);
```

**W05: Housekeeping: delete incident reports that expired before June 2026**

```sql
DELETE FROM incident_reports
WHERE expires_at < '2026-06-01';
```
