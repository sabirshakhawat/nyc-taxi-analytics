-- Match the displayed zone analysis, including its presentation rounding.
WITH enriched_metrics AS (
    SELECT COUNT(*) AS total_trips,
           SUM(fare_amount) AS total_metered_fares,
           SUM(total_amount) AS total_passenger_amount,
           SUM(passenger_count) AS total_reported_passengers,
           COUNT(DISTINCT (pickup_zone, pickup_borough)) AS zone_groups
    FROM enriched_yellow_trips
),
zone_analysis AS (
    SELECT pickup_zone, pickup_borough,
           daily_trip_count AS zone_trip_count,
           total_metered_fares,
           total_passenger_amount_paid,
           total_passengers,
           avg_passenger_per_trip
    FROM zone_performance
),
zone_totals AS (
    SELECT COUNT(*) AS result_rows,
           COUNT(DISTINCT (pickup_zone, pickup_borough)) AS distinct_zone_groups,
           SUM(zone_trip_count) AS trips,
           SUM(total_metered_fares) AS metered_fares,
           SUM(total_passenger_amount_paid) AS passenger_amount,
           SUM(total_passengers) AS reported_passengers
    FROM zone_analysis
),
-- Verify the displayed average uses trips with a reported passenger count.
zone_average_errors AS (
    SELECT COUNT(*) FILTER (
               WHERE a.avg_passenger_per_trip IS DISTINCT FROM
                     ROUND(e.reported_passengers * 1.0 /
                           NULLIF(e.reported_trips, 0), 2)
           ) AS incorrect_averages
    FROM zone_analysis a
    JOIN (
        SELECT pickup_zone, pickup_borough,
               SUM(passenger_count) AS reported_passengers,
               COUNT(passenger_count) AS reported_trips
        FROM enriched_yellow_trips
        GROUP BY pickup_zone, pickup_borough
    ) e ON a.pickup_zone IS NOT DISTINCT FROM e.pickup_zone
       AND a.pickup_borough IS NOT DISTINCT FROM e.pickup_borough
),
checks AS (
    SELECT 1 AS check_order, 'Zone trips reconcile' AS check_name,
           z.trips AS actual_value, e.total_trips AS expected_value, 0 AS tolerance
    FROM zone_totals z CROSS JOIN enriched_metrics e
    UNION ALL
    SELECT 2, 'Zone metered fares reconcile (rounded by zone)',
           z.metered_fares, e.total_metered_fares,
           e.zone_groups * 0.005 + 0.01
    FROM zone_totals z CROSS JOIN enriched_metrics e
    UNION ALL
    SELECT 3, 'Zone passenger amounts reconcile (rounded by zone)',
           z.passenger_amount, e.total_passenger_amount,
           e.zone_groups * 0.5 + 0.01
    FROM zone_totals z CROSS JOIN enriched_metrics e
    UNION ALL
    SELECT 4, 'Zone reported passengers reconcile',
           z.reported_passengers, e.total_reported_passengers, 0
    FROM zone_totals z CROSS JOIN enriched_metrics e
    UNION ALL
    SELECT 5, 'One result row per zone and borough',
           z.result_rows, e.zone_groups, 0
    FROM zone_totals z CROSS JOIN enriched_metrics e
    UNION ALL
    SELECT 6, 'No duplicate zone and borough keys',
           result_rows - distinct_zone_groups, 0, 0
    FROM zone_totals
    UNION ALL
    SELECT 7, 'Passenger averages use reported-trip denominator',
           incorrect_averages, 0, 0
    FROM zone_average_errors
)
SELECT check_name, actual_value, expected_value,
       ROUND(actual_value - expected_value, 6) AS difference,
       CASE WHEN actual_value IS NOT NULL AND expected_value IS NOT NULL
                 AND ABS(actual_value - expected_value) <= tolerance
            THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM checks
ORDER BY check_order;
