-- Reconcile the actual hourly result, not an average of hourly averages.
WITH enriched_metrics AS (
    SELECT COUNT(*) AS total_trips,
           SUM(passenger_count) AS total_reported_passengers,
           SUM(fare_amount) AS total_metered_fares,
           SUM(total_amount) AS total_passenger_amount,
           COUNT(DISTINCT EXTRACT(HOUR FROM tpep_pickup_datetime)) AS observed_hours
    FROM enriched_yellow_trips
),
hourly_analysis AS (
    SELECT * FROM hourly_demand
),
hourly_totals AS (
    SELECT COUNT(*) AS result_rows,
           COUNT(DISTINCT pickup_hour) AS distinct_hours,
           SUM(total_trips) AS trips,
           SUM(total_reported_passengers) AS reported_passengers,
           SUM(total_metered_fares) AS metered_fares,
           SUM(total_passenger_amount) AS passenger_amount
    FROM hourly_analysis
),
hourly_formula_errors AS (
    SELECT COUNT(*) FILTER (
               WHERE a.days_observed IS DISTINCT FROM e.days_observed
                  OR a.avg_daily_trips IS DISTINCT FROM
                     ROUND(e.trips * 1.0 / e.days_observed, 2)
                  OR a.passenger_count_coverage_pct IS DISTINCT FROM
                     ROUND(100.0 * e.reported_trips / e.trips, 2)
                  OR a.avg_passenger_amount_per_trip IS DISTINCT FROM
                     ROUND(e.passenger_amount / e.trips, 2)
                  OR a.avg_trip_distance_miles IS DISTINCT FROM
                     ROUND(e.distance_miles / e.trips, 2)
                  OR a.avg_trip_duration_minutes IS DISTINCT FROM
                     ROUND(e.duration_minutes / e.trips, 2)
           ) AS incorrect_hourly_metrics
    FROM hourly_analysis a
    JOIN (
        SELECT EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
               COUNT(*) AS trips,
               COUNT(passenger_count) AS reported_trips,
               COUNT(DISTINCT pickup_date) AS days_observed,
               SUM(total_amount) AS passenger_amount,
               SUM(trip_distance) AS distance_miles,
               SUM(trip_duration_minutes) AS duration_minutes
        FROM enriched_yellow_trips
        GROUP BY pickup_hour
    ) e USING (pickup_hour)
),
checks AS (
    SELECT 1 AS check_order, 'Hourly trips reconcile' AS check_name,
           h.trips AS actual_value, e.total_trips AS expected_value, 0 AS tolerance
    FROM hourly_totals h CROSS JOIN enriched_metrics e
    UNION ALL SELECT 2, 'Hourly reported passengers reconcile',
           h.reported_passengers, e.total_reported_passengers, 0
    FROM hourly_totals h CROSS JOIN enriched_metrics e
    UNION ALL SELECT 3, 'Hourly metered fares reconcile (rounded by hour)',
           h.metered_fares, e.total_metered_fares, e.observed_hours * 0.005 + 0.01
    FROM hourly_totals h CROSS JOIN enriched_metrics e
    UNION ALL SELECT 4, 'Hourly passenger amounts reconcile (rounded by hour)',
           h.passenger_amount, e.total_passenger_amount, e.observed_hours * 0.005 + 0.01
    FROM hourly_totals h CROSS JOIN enriched_metrics e
    UNION ALL SELECT 5, 'One result row per observed hour',
           h.result_rows, e.observed_hours, 0
    FROM hourly_totals h CROSS JOIN enriched_metrics e
    UNION ALL SELECT 6, 'No duplicate hours',
           result_rows - distinct_hours, 0, 0 FROM hourly_totals
    UNION ALL SELECT 7, 'Hourly denominators and averages match source',
           incorrect_hourly_metrics, 0, 0 FROM hourly_formula_errors
)
SELECT check_name, actual_value, expected_value,
       ROUND(actual_value - expected_value, 6) AS difference,
       CASE WHEN actual_value IS NOT NULL AND expected_value IS NOT NULL
                 AND ABS(actual_value - expected_value) <= tolerance
            THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM checks
ORDER BY check_order;
