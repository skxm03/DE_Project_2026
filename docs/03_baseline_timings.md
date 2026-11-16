# CP2 · Baseline timings

The course benchmark helper ran the original 30-query workload on PostgreSQL 18.4 (Postgres.app, Apple Silicon) against all 936,328 seed rows. The database used only the 17 indexes created by CP1 primary and unique constraints. The session time zone was `Asia/Kolkata`. Each statement ran three times with `EXPLAIN (ANALYZE, BUFFERS)`; each write was rolled back separately.

Times are PostgreSQL's reported execution times, in milliseconds. See the [benchmark summary table](../benchmarks/results/baseline/summary.md) for the median, range and scan nodes, or the [source CSV](../benchmarks/results/baseline/summary.csv).

**Slowest query:** R19 averaged 13,620.371 ms. R19 evaluates two correlated aggregates per hospital, repeatedly scanning navigation sessions. The baseline also keeps R13 as supplied, including its NULL-sensitive `NOT IN` behavior. Both are candidates for CP3.

## All 30 timings

| Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01 | READ | 3.939 | 3.433 | 3.285 | 3.552 |
| R02 | READ | 0.040 | 0.039 | 0.039 | 0.039 |
| R03 | READ | 13.606 | 14.014 | 13.749 | 13.790 |
| R04 | READ | 10.674 | 8.518 | 9.076 | 9.423 |
| R05 | READ | 0.144 | 0.140 | 0.137 | 0.140 |
| R06 | READ | 0.429 | 0.070 | 0.059 | 0.186 |
| R07 | READ | 3.575 | 4.186 | 3.757 | 3.839 |
| R08 | READ | 0.366 | 0.375 | 0.356 | 0.366 |
| R09 | READ | 0.591 | 0.231 | 0.225 | 0.349 |
| R10 | READ | 0.878 | 0.809 | 0.763 | 0.817 |
| R11 | READ | 22.295 | 22.304 | 22.335 | 22.311 |
| R12 | READ | 10.536 | 10.225 | 10.147 | 10.303 |
| R13 | READ | 19.617 | 20.711 | 20.315 | 20.214 |
| R14 | READ | 9.945 | 9.159 | 9.225 | 9.443 |
| R15 | READ | 30.613 | 30.647 | 30.306 | 30.522 |
| R16 | READ | 13.041 | 13.357 | 13.496 | 13.298 |
| R17 | READ | 32.357 | 33.461 | 32.576 | 32.798 |
| R18 | READ | 15.037 | 14.850 | 14.155 | 14.681 |
| R19 | READ | 13536.062 | 13812.141 | 13512.909 | 13620.371 |
| R20 | READ | 10.266 | 9.843 | 10.445 | 10.185 |
| R21 | READ | 21.151 | 21.000 | 21.239 | 21.130 |
| R22 | READ | 16.730 | 16.580 | 16.598 | 16.636 |
| R23 | READ | 0.026 | 0.023 | 0.023 | 0.024 |
| R24 | READ | 4.700 | 5.015 | 4.730 | 4.815 |
| R25 | READ | 27.687 | 28.509 | 27.721 | 27.972 |
| W01 | WRITE | 0.992 | 0.592 | 0.510 | 0.698 |
| W02 | WRITE | 0.599 | 0.489 | 0.573 | 0.554 |
| W03 | WRITE | 0.554 | 0.607 | 0.588 | 0.583 |
| W04 | WRITE | 32.183 | 34.676 | 34.322 | 33.727 |
| W05 | WRITE | 2.073 | 2.244 | 2.166 | 2.161 |
