# CP4 · Large dataset benchmark summary

Native PostgreSQL 18.6 · 30 queries · 3 runs per query. All timings are in milliseconds. Scan nodes are from the final run.

[Source CSV](summary.csv)

## Read queries

| Query | Type | Average (ms) | Median (ms) | Min (ms) | Max (ms) | Scan nodes |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| R01 | READ | 2.219 | 1.814 | 1.511 | 3.332 | Index Scan using cp3_places_nearby on places |
| R02 | READ | 0.351 | 0.359 | 0.149 | 0.545 | Index Scan using places_pkey on places \| Index Only Scan using cp4_opening_hours_covering on opening_hours |
| R03 | READ | 79.422 | 69.417 | 66.101 | 102.747 | Seq Scan on places |
| R04 | READ | 0.828 | 0.827 | 0.770 | 0.888 | Index Scan using cp4_places_open_now on places \| Index Only Scan using cp4_opening_hours_covering on opening_hours |
| R05 | READ | 0.124 | 0.132 | 0.099 | 0.142 | Index Scan using cp4_reviews_place_created on place_reviews \| Index Scan using users_pkey on users |
| R06 | READ | 0.063 | 0.067 | 0.054 | 0.068 | Index Scan using saved_places_pkey on saved_places \| Index Scan using places_pkey on places |
| R07 | READ | 5.224 | 5.354 | 4.080 | 6.239 | Index Only Scan using cp4_road_segments_filter on road_segments \| Index Only Scan using cp4_traffic_covering on traffic_readings |
| R08 | READ | 1.347 | 1.347 | 1.130 | 1.565 | Index Scan using cp3_traffic_alert_time on traffic_readings \| Index Only Scan using cp4_road_segments_filter on road_segments |
| R09 | READ | 0.299 | 0.304 | 0.277 | 0.316 | Index Only Scan using cp4_traffic_covering on traffic_readings |
| R10 | READ | 1.260 | 1.057 | 1.051 | 1.672 | Index Scan using cp3_incidents_reported_at on incident_reports \| Index Only Scan using cp4_road_segments_filter on road_segments |
| R11 | READ | 586.871 | 589.214 | 549.829 | 621.569 | Bitmap Heap Scan on navigation_sessions \| Bitmap Index Scan on cp4_nav_recent_started |
| R12 | READ | 27.958 | 25.189 | 24.602 | 34.084 | Seq Scan on places \| Index Only Scan using cp4_nav_recent_started on navigation_sessions |
| R13 | READ | 119.354 | 117.145 | 114.432 | 126.485 | Seq Scan on places \| Index Only Scan using cp3_nav_origin_place on navigation_sessions |
| R14 | READ | 62.930 | 60.999 | 58.489 | 69.302 | Seq Scan on users \| Index Scan using cp3_reviews_moderation on place_reviews |
| R15 | READ | 878.854 | 874.112 | 871.412 | 891.037 | Index Scan using place_reviews_place_id_user_id_key on place_reviews \| Index Scan using places_pkey on places |
| R16 | READ | 38.818 | 37.705 | 37.103 | 41.646 | Seq Scan on places \| Index Only Scan using cp3_nav_destination_started on navigation_sessions |
| R17 | READ | 1357.705 | 1288.899 | 1271.516 | 1512.701 | Seq Scan on navigation_sessions |
| R18 | READ | 193.616 | 188.017 | 175.382 | 217.450 | Seq Scan on navigation_sessions |
| R19 | READ | 40.403 | 39.401 | 38.636 | 43.172 | Seq Scan on place_categories \| Seq Scan on places \| Index Only Scan using cp3_nav_destination_started on navigation_sessions |
| R20 | READ | 34.029 | 33.964 | 33.853 | 34.270 | Index Only Scan using cp3_nav_june_started on navigation_sessions |
| R21 | READ | 529.749 | 559.755 | 443.752 | 585.741 | Seq Scan on opening_hours \| Seq Scan on places \| Seq Scan on place_categories |
| R22 | READ | 3.529 | 3.598 | 3.340 | 3.650 | Index Only Scan using cp3_reviews_moderation on place_reviews |
| R23 | READ | 0.035 | 0.032 | 0.031 | 0.043 | Index Scan using places_plus_code_key on places |
| R24 | READ | 52.870 | 50.568 | 50.497 | 57.544 | Seq Scan on places |
| R25 | READ | 381.556 | 376.248 | 372.001 | 396.418 | Seq Scan on traffic_readings \| Seq Scan on road_segments |

## Write queries

| Query | Type | Average (ms) | Median (ms) | Min (ms) | Max (ms) | Scan nodes |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| W01 | WRITE | 0.829 | 0.768 | 0.718 | 1.001 | (no scan) |
| W02 | WRITE | 0.877 | 0.957 | 0.691 | 0.984 | (no scan) |
| W03 | WRITE | 1.366 | 0.932 | 0.864 | 2.303 | (no scan) |
| W04 | WRITE | 1203.803 | 1211.703 | 1121.695 | 1278.011 | Index Scan using place_reviews_place_id_user_id_key on place_reviews \| Index Scan using places_pkey on places |
| W05 | WRITE | 49.615 | 44.025 | 41.610 | 63.209 | Seq Scan on incident_reports |
