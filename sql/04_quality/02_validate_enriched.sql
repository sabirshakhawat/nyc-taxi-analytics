WITH staging_metrics AS (
    SELECT COUNT(*) AS total_staging_rows,
           COUNT(*) FILTER (
            WHERE is_valid_completed_trip = TRUE
           ) AS valid_rows,
           COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS NOT TRUE
           ) AS invalid_rows
    FROM stg_yellow_trips
),

lookup_metrics AS(
    SELECT COUNT(LocationID) - COUNT(DISTINCT LocationID) AS duplicate_location_ids
    FROM read_csv('data/reference/taxi_zone_lookup.csv')
),

enriched_metrics AS(
    SELECT COUNT(*) AS total_rows,
           COUNT(*) FILTER(
           WHERE tpep_pickup_datetime < TIMESTAMP '2026-01-01'
           OR
           tpep_pickup_datetime >= TIMESTAMP '2026-02-01'
           ) AS rows_outside_january,
           COUNT(*) FILTER (
            WHERE is_valid_completed_trip = FALSE
           ) AS invalid_trips,
           COUNT(*) FILTER(
            WHERE trip_distance > 500 OR trip_distance <=0 OR trip_distance IS NULL
           ) AS invalid_trip_distance,
           COUNT(*) FILTER(
            WHERE tpep_dropoff_datetime <= tpep_pickup_datetime
           ) AS invalid_trip_duration,
           COUNT(*) FILTER(
            WHERE total_amount <= 0 OR fare_amount < 0
           ) AS invalid_amount,
           COUNT(*) FILTER (
            WHERE dropoff_zone = 'Outside of NYC'
            OR pickup_zone = 'Outside of NYC'
           ) AS outside_nyc_trips,
           COUNT(*) FILTER (
            WHERE pickup_zone IS NULL
           ) AS null_pickup_zone,
           COUNT(*) FILTER (
            WHERE dropoff_zone IS NULL
           ) AS null_dropoff_zone,
           COUNT(*) FILTER (
            WHERE passenger_count IS NULL
           ) AS missing_passenger_count --coverage warning


    FROM enriched_yellow_trips
),

zone_label_metrics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE pickup.LocationID IS NULL
               OR trips.pickup_zone IS DISTINCT FROM pickup.Zone
               OR trips.pickup_borough IS DISTINCT FROM pickup.Borough
        ) AS incorrect_pickup_labels,
        COUNT(*) FILTER (
            WHERE dropoff.LocationID IS NULL
               OR trips.dropoff_zone IS DISTINCT FROM dropoff.Zone
               OR trips.dropoff_borough IS DISTINCT FROM dropoff.Borough
        ) AS incorrect_dropoff_labels
    FROM enriched_yellow_trips AS trips
    LEFT JOIN read_csv('data/reference/taxi_zone_lookup.csv') AS pickup
        ON trips.PULocationID = pickup.LocationID
    LEFT JOIN read_csv('data/reference/taxi_zone_lookup.csv') AS dropoff
        ON trips.DOLocationID = dropoff.LocationID
),

checks AS(
    SELECT 1 as check_order,
    'Enriched row count matches valid staging count' AS check_name,
     total_rows AS actual_value,
     valid_rows AS expected_value
     FROM enriched_metrics
     CROSS JOIN staging_metrics

     UNION ALL

     SELECT 2,
        'Enriched rows outside January',
        rows_outside_january,
        0
    FROM enriched_metrics

    UNION ALL

    SELECT
        3,
        'Invalid trips present in enriched',
        invalid_trips,
        0
    FROM enriched_metrics

    UNION ALL

    SELECT
        4,
        'Enriched trips violating distance rules',
        invalid_trip_distance,
        0
    FROM enriched_metrics

    UNION ALL

    SELECT
        5,
        'Enriched trips with nonpositive duration',
        invalid_trip_duration,
        0
    FROM enriched_metrics

    UNION ALL

    SELECT
        6,
        'Enriched trips with invalid amounts',
        invalid_amount,
        0
    FROM enriched_metrics

    UNION ALL

    SELECT 7,
           'Enriched trips with null pickup zone',
           null_pickup_zone,
           0
    FROM enriched_metrics

    UNION ALL

    SELECT 8,
           'Enriched trips with null dropoff zone',
           null_dropoff_zone,
           0
    FROM enriched_metrics


    UNION ALL

    SELECT
        9,
        'Duplicate location IDs in lookup',
        duplicate_location_ids,
        0
    FROM lookup_metrics

    UNION ALL

    SELECT 10,
           'Pickup labels match pickup location ID',
           incorrect_pickup_labels,
           0
    FROM zone_label_metrics

    UNION ALL

    SELECT 11,
           'Dropoff labels match dropoff location ID',
           incorrect_dropoff_labels,
           0
    FROM zone_label_metrics
)
    SELECT
    check_name,
    actual_value,
    expected_value,
    CASE
        WHEN actual_value = expected_value THEN 'PASS'
        ELSE 'FAIL'
    END AS check_status
FROM checks
ORDER BY check_order;

    
