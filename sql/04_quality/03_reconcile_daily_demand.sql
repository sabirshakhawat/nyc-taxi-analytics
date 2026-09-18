WITH enriched_totals AS (
    SELECT COUNT(*) AS total_trips,
    SUM(fare_amount) AS total_metered_fares,
    SUM(total_amount) AS total_amount_earned,
    SUM(trip_duration_minutes) AS total_trip_duration,
    SUM(passenger_count) AS total_passenger_count,
    COUNT(*) FILTER(
    WHERE passenger_count IS NOT NULL
    ) AS trips_with_passenger_count,
    COUNT(*) FILTER (
    WHERE passenger_count IS NULL
    ) AS trips_missing_passenger_count,
    SUM(trip_distance) AS total_trip_distance,
    COUNT(*) FILTER (
     WHERE PULocationID = DOLocationID
     ) AS same_zone_trip_count,
    COUNT(*) FILTER (
     WHERE PULocationID != DOLocationID
    ) AS cross_zone_trip_count,
    COUNT(DISTINCT pickup_date) AS days_observed,
    MIN(pickup_date) AS min_pickup_date,
    MAX(pickup_date) AS max_pickup_date,
    COUNT(DISTINCT pickup_borough) AS boroughs_observed,
    COUNT(DISTINCT pickup_zone) AS zones_observed
    FROM enriched_yellow_trips
),

enriched_metrics AS (
    SELECT *,
           (total_amount_earned/total_trips) AS avg_amount_per_trip,
           (total_passenger_count/trips_with_passenger_count) AS avg_passengers_per_reported_trip,
           (total_trip_distance/total_trips) AS avg_distance_per_trip,
           (total_trip_duration/ total_trips) AS avg_trip_duration_per_passenger,
           ((trips_with_passenger_count / total_trips) * 100) AS passenger_count_coverage_pct
    FROM enriched_totals
),

daily_demand_validation AS (
    SELECT pickup_date,
           daily_trip_count,
           total_metered_fares AS daily_metered_fares,
           total_passenger_amount_paid AS daily_amount_earned,
           total_passengers AS daily_reported_passengers,
           avg_passenger_amount AS daily_avg_reported_passengers
    FROM daily_demand_revenue
),

daily_demand_totals AS (
    SELECT COUNT(*) AS daily_rows,
           COUNT(DISTINCT pickup_date) AS distinct_daily_dates,
           SUM(daily_trip_count) AS reconciled_trip_count,
           SUM(daily_metered_fares) AS reconciled_metered_fares,
           SUM(daily_amount_earned) AS reconciled_amount_earned,
           SUM(daily_reported_passengers) AS reconciled_reported_passengers,
           COUNT(*) FILTER (WHERE daily_avg_reported_passengers IS NULL)
               AS days_without_passenger_average
    FROM daily_demand_validation
),

daily_average_errors AS (
    SELECT COUNT(*) FILTER (
        WHERE a.daily_avg_reported_passengers IS DISTINCT FROM e.expected_average
          AND (a.daily_avg_reported_passengers IS NULL
               OR e.expected_average IS NULL
               OR ABS(a.daily_avg_reported_passengers - e.expected_average) > 0.000001)
    ) AS incorrect_averages
    FROM daily_demand_validation a
    JOIN (
        SELECT pickup_date, AVG(passenger_count) AS expected_average
        FROM enriched_yellow_trips
        GROUP BY pickup_date
    ) e USING (pickup_date)
),

daily_checks AS (
    SELECT 1 AS check_order,
           'Daily trip counts reconcile to enriched trips' AS check_name,
           reconciled_trip_count AS actual_value,
           total_trips AS expected_value,
           0 AS tolerance
    FROM daily_demand_totals
    CROSS JOIN enriched_metrics

    UNION ALL

    SELECT 2,
           'Daily metered fares reconcile to enriched trips',
           reconciled_metered_fares,
           total_metered_fares,
           0.01
    FROM daily_demand_totals
    CROSS JOIN enriched_metrics

    UNION ALL

    SELECT 3,
           'Daily passenger amounts reconcile to enriched trips',
           reconciled_amount_earned,
           total_amount_earned,
           0.01
    FROM daily_demand_totals
    CROSS JOIN enriched_metrics

    UNION ALL

    SELECT 4,
           'Daily reported passengers reconcile to enriched trips',
           reconciled_reported_passengers,
           total_passenger_count,
           0
    FROM daily_demand_totals
    CROSS JOIN enriched_metrics

    UNION ALL

    SELECT 5,
           'Daily result contains one row per observed date',
           daily_rows,
           days_observed,
           0
    FROM daily_demand_totals
    CROSS JOIN enriched_metrics

    UNION ALL

    SELECT 6,
           'Daily result has no duplicate dates',
           daily_rows - distinct_daily_dates,
           0,
           0
    FROM daily_demand_totals

    UNION ALL

    SELECT 7,
           'Daily passenger averages match enriched trips',
           incorrect_averages,
           0,
           0
    FROM daily_average_errors
)

SELECT check_name,
       actual_value,
       expected_value,
       ROUND(actual_value - expected_value, 6) AS difference,
       CASE
           WHEN ABS(actual_value - expected_value) <= tolerance THEN 'PASS'
           ELSE 'FAIL'
       END AS check_status
FROM daily_checks
ORDER BY check_order;
