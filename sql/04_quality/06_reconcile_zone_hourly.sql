-- The published zone-hour values are averages per active day. Reconcile the
-- unrounded date/zone/hour inputs before checking those displayed averages.
WITH enriched_metrics AS (
    SELECT COUNT(*) AS total_trips,
           SUM(passenger_count) AS total_reported_passengers,
           SUM(total_amount) AS total_passenger_amount,
           SUM(trip_distance) AS total_trip_distance,
           SUM(trip_duration_minutes) AS total_trip_duration,
           COUNT(DISTINCT (EXTRACT(HOUR FROM tpep_pickup_datetime),
                           pickup_borough, pickup_zone)) AS zone_hour_groups
    FROM enriched_yellow_trips
),
zone_hourly_demand AS (
    SELECT pickup_date,
           EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
           pickup_borough, pickup_zone,
           COUNT(*) AS trips_in_hour,
           SUM(passenger_count) AS hourly_passenger_count,
           SUM(total_amount) AS hourly_passenger_amount,
           SUM(trip_distance) AS hourly_trip_distance,
           SUM(trip_duration_minutes) AS hourly_trip_duration_minutes
    FROM enriched_yellow_trips
    GROUP BY pickup_date, pickup_hour, pickup_borough, pickup_zone
),
zone_hourly_analysis AS (
    SELECT pickup_hour AS pickup_hour_of_the_day,
           pickup_zone, pickup_borough,
           ROUND(AVG(trips_in_hour)) AS avg_trips_per_active_day,
           ROUND(AVG(hourly_passenger_count)) AS avg_reported_passengers_per_active_day,
           ROUND(AVG(hourly_passenger_amount)) AS avg_passenger_amount_per_active_day,
           ROUND(AVG(hourly_trip_distance)) AS avg_trip_miles_per_active_day,
           ROUND(AVG(hourly_trip_duration_minutes)) AS avg_trip_minutes_per_active_day
    FROM zone_hourly_demand
    GROUP BY pickup_hour_of_the_day, pickup_borough, pickup_zone
),
zone_hourly_totals AS (
    SELECT COUNT(*) AS intermediate_rows,
           COUNT(DISTINCT (pickup_date, pickup_hour, pickup_borough, pickup_zone))
               AS distinct_intermediate_keys,
           SUM(trips_in_hour) AS trips,
           SUM(hourly_passenger_count) AS reported_passengers,
           SUM(hourly_passenger_amount) AS passenger_amount,
           SUM(hourly_trip_distance) AS trip_distance,
           SUM(hourly_trip_duration_minutes) AS trip_duration
    FROM zone_hourly_demand
),
final_grain AS (
    SELECT COUNT(*) AS result_rows,
           COUNT(DISTINCT (pickup_hour_of_the_day, pickup_borough, pickup_zone))
               AS distinct_result_keys
    FROM zone_hourly_analysis
),
average_errors AS (
    SELECT COUNT(*) FILTER (
               WHERE a.avg_trips_per_active_day IS DISTINCT FROM
                     ROUND(e.trips * 1.0 / e.active_days)
                  OR a.avg_reported_passengers_per_active_day IS DISTINCT FROM
                     ROUND(e.reported_passengers * 1.0 /
                           NULLIF(e.days_with_passenger_data, 0))
                  OR a.avg_passenger_amount_per_active_day IS DISTINCT FROM
                     ROUND(e.passenger_amount / e.active_days)
                  OR a.avg_trip_miles_per_active_day IS DISTINCT FROM
                     ROUND(e.trip_distance / e.active_days)
                  OR a.avg_trip_minutes_per_active_day IS DISTINCT FROM
                     ROUND(e.trip_duration / e.active_days)
           ) AS incorrect_averages
    FROM zone_hourly_analysis a
    JOIN (
        SELECT pickup_hour, pickup_borough, pickup_zone,
               COUNT(*) AS active_days,
               COUNT(hourly_passenger_count) AS days_with_passenger_data,
               SUM(trips_in_hour) AS trips,
               SUM(hourly_passenger_count) AS reported_passengers,
               SUM(hourly_passenger_amount) AS passenger_amount,
               SUM(hourly_trip_distance) AS trip_distance,
               SUM(hourly_trip_duration_minutes) AS trip_duration
        FROM zone_hourly_demand
        GROUP BY pickup_hour, pickup_borough, pickup_zone
    ) e ON a.pickup_hour_of_the_day = e.pickup_hour
       AND a.pickup_borough IS NOT DISTINCT FROM e.pickup_borough
       AND a.pickup_zone IS NOT DISTINCT FROM e.pickup_zone
),
checks AS (
    SELECT 1 AS check_order, 'Zone-hour underlying trips reconcile' AS check_name,
           z.trips AS actual_value, e.total_trips AS expected_value, 0 AS tolerance
    FROM zone_hourly_totals z CROSS JOIN enriched_metrics e
    UNION ALL SELECT 2, 'Zone-hour reported passengers reconcile',
           z.reported_passengers, e.total_reported_passengers, 0
    FROM zone_hourly_totals z CROSS JOIN enriched_metrics e
    UNION ALL SELECT 3, 'Zone-hour passenger amounts reconcile',
           z.passenger_amount, e.total_passenger_amount, 0.01
    FROM zone_hourly_totals z CROSS JOIN enriched_metrics e
    UNION ALL SELECT 4, 'Zone-hour trip distance reconciles',
           z.trip_distance, e.total_trip_distance, 0.01
    FROM zone_hourly_totals z CROSS JOIN enriched_metrics e
    UNION ALL SELECT 5, 'Zone-hour trip duration reconciles',
           z.trip_duration, e.total_trip_duration, 0.01
    FROM zone_hourly_totals z CROSS JOIN enriched_metrics e
    UNION ALL SELECT 6, 'No duplicate date-zone-hour keys',
           intermediate_rows - distinct_intermediate_keys, 0, 0
    FROM zone_hourly_totals
    UNION ALL SELECT 7, 'One result row per zone and hour',
           f.result_rows, e.zone_hour_groups, 0
    FROM final_grain f CROSS JOIN enriched_metrics e
    UNION ALL SELECT 8, 'No duplicate zone-hour result keys',
           result_rows - distinct_result_keys, 0, 0 FROM final_grain
    UNION ALL SELECT 9, 'Zone-hour active-day averages match inputs',
           incorrect_averages, 0, 0 FROM average_errors
)
SELECT check_name, actual_value, expected_value,
       ROUND(actual_value - expected_value, 6) AS difference,
       CASE WHEN actual_value IS NOT NULL AND expected_value IS NOT NULL
                 AND ABS(actual_value - expected_value) <= tolerance
            THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM checks
ORDER BY check_order;
