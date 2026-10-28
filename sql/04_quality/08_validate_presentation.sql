WITH checks AS (
    SELECT 'Airport segments preserve all eligible trips' AS check_name,
           (SELECT SUM(total_trips) FROM airport_comparison) AS actual_value,
           (SELECT COUNT(*) FROM enriched_yellow_trips) AS expected_value, 0.0 AS tolerance
    UNION ALL
    SELECT 'Airport payments reconcile',
           (SELECT SUM(total_recorded_payment_usd) FROM airport_comparison),
           (SELECT SUM(total_amount) FROM enriched_yellow_trips), 0.02
    UNION ALL
    SELECT 'Exactly five priority zones', COUNT(*), 5, 0 FROM priority_windows
    UNION ALL
    SELECT 'Priority zone IDs are unique', COUNT(DISTINCT pickup_location_id), 5, 0
    FROM priority_windows
    UNION ALL
    SELECT 'January has the expected calendar span',
           DATE_DIFF('day', MIN(pickup_date), MAX(pickup_date)) + 1, 31, 0
    FROM enriched_yellow_trips
    UNION ALL
    SELECT 'Peak averages use all 31 days', COUNT(*), 0, 0
    FROM priority_windows p
    WHERE ABS(p.avg_peak_hour_trips_per_calendar_day - (
        SELECT COUNT(*) / 31.0 FROM enriched_yellow_trips e
        WHERE e.PULocationID = p.pickup_location_id
          AND EXTRACT(HOUR FROM e.tpep_pickup_datetime) = p.peak_hour
    )) > 0.0051
)
SELECT *, CASE WHEN ABS(actual_value - expected_value) <= tolerance
              THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks;
