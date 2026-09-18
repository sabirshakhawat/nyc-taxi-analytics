-- Keep unrounded route totals to reconcile; the report displays per-trip averages.
WITH enriched_metrics AS (
    SELECT COUNT(*) AS total_trips,
           SUM(total_amount) AS total_passenger_amount,
           SUM(trip_distance) AS total_trip_distance,
           SUM(trip_duration_minutes) AS total_trip_duration,
           COUNT(*) FILTER (WHERE PULocationID = DOLocationID) AS same_zone_trips,
           COUNT(*) FILTER (WHERE PULocationID <> DOLocationID) AS cross_zone_trips,
           COUNT(DISTINCT (pickup_zone, dropoff_zone,
                  CASE WHEN PULocationID = DOLocationID
                       THEN 'Same-Zone' ELSE 'Cross-Zone' END)) AS route_groups
    FROM enriched_yellow_trips
),
route_performance AS (
    SELECT * FROM main.route_performance
),
route_analysis AS (
    SELECT * FROM main.route_analysis
),
route_totals AS (
    SELECT COUNT(*) AS result_rows,
           COUNT(DISTINCT (pickup_zone, dropoff_zone, route_category))
               AS distinct_route_keys,
           SUM(route_total_trips) AS trips,
           SUM(route_total_amount) AS passenger_amount,
           SUM(route_total_trip_distance) AS trip_distance,
           SUM(route_total_trip_duration) AS trip_duration,
           SUM(route_total_trips) FILTER (WHERE route_category = 'Same-Zone')
               AS same_zone_trips,
           SUM(route_total_trips) FILTER (WHERE route_category = 'Cross-Zone')
               AS cross_zone_trips
    FROM route_performance
),
route_average_errors AS (
    SELECT COUNT(*) FILTER (
               WHERE a.route_total_trips IS DISTINCT FROM r.route_total_trips
                  OR ABS(a.avg_route_amount -
                         r.route_total_amount / r.route_total_trips) > 0.005001
                  OR ABS(a.avg_route_trip_distance -
                         r.route_total_trip_distance / r.route_total_trips) > 0.005001
                  OR ABS(a.avg_route_trip_duration -
                         r.route_total_trip_duration / r.route_total_trips) > 0.500001
           ) AS incorrect_route_averages
    FROM route_analysis a
    JOIN route_performance r
      ON a.pickup_zone IS NOT DISTINCT FROM r.pickup_zone
     AND a.dropoff_zone IS NOT DISTINCT FROM r.dropoff_zone
     AND a.route_category = r.route_category
),
checks AS (
    SELECT 1 AS check_order, 'Route trips reconcile' AS check_name,
           r.trips AS actual_value, e.total_trips AS expected_value, 0 AS tolerance
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 2, 'Route passenger amounts reconcile',
           r.passenger_amount, e.total_passenger_amount, 0.01
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 3, 'Route trip distances reconcile',
           r.trip_distance, e.total_trip_distance, 0.01
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 4, 'Route trip durations reconcile',
           r.trip_duration, e.total_trip_duration, 0.01
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 5, 'Same-zone routes reconcile by location ID',
           r.same_zone_trips, e.same_zone_trips, 0
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 6, 'Cross-zone routes reconcile by location ID',
           r.cross_zone_trips, e.cross_zone_trips, 0
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 7, 'Route categories account for all trips',
           same_zone_trips + cross_zone_trips, trips, 0 FROM route_totals
    UNION ALL SELECT 8, 'One result row per route and category',
           r.result_rows, e.route_groups, 0
    FROM route_totals r CROSS JOIN enriched_metrics e
    UNION ALL SELECT 9, 'No duplicate route-category keys',
           result_rows - distinct_route_keys, 0, 0 FROM route_totals
    UNION ALL SELECT 10, 'Route averages match unrounded totals',
           incorrect_route_averages, 0, 0 FROM route_average_errors
)
SELECT check_name, actual_value, expected_value,
       ROUND(actual_value - expected_value, 6) AS difference,
       CASE WHEN actual_value IS NOT NULL AND expected_value IS NOT NULL
                 AND ABS(actual_value - expected_value) <= tolerance
            THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM checks
ORDER BY check_order;
