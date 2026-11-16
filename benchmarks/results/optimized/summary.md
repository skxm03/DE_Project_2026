# CP3 · Optimized benchmark summary

Native PostgreSQL 18.4 · 30 queries · 3 runs per query. All timings are in milliseconds. Scan nodes are from the final run.

[Checkpoint report](../../../docs/04_optimization_report.md) · [Source CSV](summary.csv)

## Read queries

| Query | Type | Average (ms) | Median (ms) | Min (ms) | Max (ms) | Scan nodes |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| R01 | READ | 0.129 | 0.122 | 0.120 | 0.145 | Index Scan using cp3_places_nearby on places |
| R02 | READ | 0.043 | 0.043 | 0.041 | 0.045 | Index Scan using places_pkey on places \| Index Scan using opening_hours_pkey on opening_hours |
| R03 | READ | 13.858 | 13.794 | 13.759 | 14.021 | Seq Scan on places |
| R04 | READ | 6.819 | 6.803 | 6.743 | 6.911 | Seq Scan on opening_hours \| Bitmap Heap Scan on places \| Bitmap Index Scan on cp3_places_nearby |
| R05 | READ | 0.132 | 0.127 | 0.127 | 0.141 | Bitmap Heap Scan on place_reviews \| Bitmap Index Scan on place_reviews_place_id_user_id_key \| Index Scan using users_pkey on users |
| R06 | READ | 0.058 | 0.057 | 0.056 | 0.061 | Index Scan using saved_places_pkey on saved_places \| Index Scan using places_pkey on places |
| R07 | READ | 0.248 | 0.240 | 0.239 | 0.265 | Seq Scan on road_segments \| Index Scan using traffic_readings_segment_id_recorded_at_key on traffic_readings |
| R08 | READ | 0.119 | 0.111 | 0.110 | 0.136 | Index Scan using cp3_traffic_alert_time on traffic_readings \| Seq Scan on road_segments |
| R09 | READ | 0.212 | 0.212 | 0.211 | 0.212 | Bitmap Heap Scan on traffic_readings \| Bitmap Index Scan on traffic_readings_segment_id_recorded_at_key |
| R10 | READ | 0.114 | 0.112 | 0.111 | 0.120 | Index Scan using cp3_incidents_reported_at on incident_reports \| Seq Scan on road_segments |
| R11 | READ | 21.601 | 21.568 | 21.472 | 21.764 | Seq Scan on navigation_sessions |
| R12 | READ | 4.874 | 4.472 | 4.397 | 5.752 | Index Only Scan using cp3_nav_destination_started on navigation_sessions \| Seq Scan on places |
| R13 | READ | 6.058 | 6.014 | 5.994 | 6.167 | Index Only Scan using cp3_nav_origin_place on navigation_sessions \| Seq Scan on places |
| R14 | READ | 5.752 | 5.783 | 5.675 | 5.797 | Index Scan using cp3_reviews_moderation on place_reviews \| Seq Scan on users |
| R15 | READ | 23.182 | 23.327 | 22.871 | 23.349 | Seq Scan on places \| Seq Scan on place_reviews |
| R16 | READ | 3.875 | 3.903 | 3.798 | 3.925 | Seq Scan on places \| Index Only Scan using cp3_nav_destination_started on navigation_sessions |
| R17 | READ | 30.415 | 30.478 | 30.215 | 30.551 | Seq Scan on navigation_sessions |
| R18 | READ | 14.007 | 13.913 | 13.778 | 14.330 | Seq Scan on navigation_sessions |
| R19 | READ | 3.932 | 3.872 | 3.611 | 4.312 | Seq Scan on place_categories \| Seq Scan on places \| Index Only Scan using cp3_nav_destination_started on navigation_sessions |
| R20 | READ | 1.369 | 1.368 | 1.357 | 1.382 | Index Only Scan using cp3_nav_june_started on navigation_sessions |
| R21 | READ | 20.235 | 20.280 | 19.978 | 20.447 | Seq Scan on opening_hours \| Seq Scan on places \| Seq Scan on place_categories |
| R22 | READ | 3.004 | 2.901 | 2.805 | 3.305 | Index Only Scan using cp3_reviews_moderation on place_reviews |
| R23 | READ | 0.021 | 0.022 | 0.019 | 0.022 | Index Scan using places_plus_code_key on places |
| R24 | READ | 4.473 | 4.449 | 4.439 | 4.532 | Seq Scan on places |
| R25 | READ | 25.283 | 25.334 | 25.162 | 25.352 | Seq Scan on traffic_readings \| Seq Scan on road_segments |

## Write queries

| Query | Type | Average (ms) | Median (ms) | Min (ms) | Max (ms) | Scan nodes |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| W01 | WRITE | 0.516 | 0.512 | 0.502 | 0.534 | (no scan) |
| W02 | WRITE | 0.465 | 0.452 | 0.442 | 0.502 | (no scan) |
| W03 | WRITE | 0.484 | 0.484 | 0.459 | 0.509 | (no scan) |
| W04 | WRITE | 29.667 | 29.608 | 29.467 | 29.925 | Seq Scan on places \| Seq Scan on place_reviews |
| W05 | WRITE | 1.926 | 1.926 | 1.904 | 1.949 | Seq Scan on incident_reports |
