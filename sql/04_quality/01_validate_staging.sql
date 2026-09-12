-- validate that the staging view contains the intended january population
-- and that its row-level quality flags agree with is_valid_completed_trip.

WITH raw_metrics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE tpep_pickup_datetime >= TIMESTAMP '2026-01-01'
              AND tpep_pickup_datetime < TIMESTAMP '2026-02-01'
        ) AS raw_january_rows
    FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')
),

staging_metrics AS (
    SELECT
        COUNT(*) AS staging_rows,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS TRUE
        ) AS valid_rows,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS FALSE
        ) AS invalid_rows,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS NULL
        ) AS unclassified_rows,
        COUNT(*) FILTER (
            WHERE tpep_pickup_datetime IS NULL
               OR tpep_pickup_datetime < TIMESTAMP '2026-01-01'
               OR tpep_pickup_datetime >= TIMESTAMP '2026-02-01'
        ) AS rows_outside_january,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS TRUE
              AND has_nonpositive_duration IS TRUE
        ) AS valid_rows_with_nonpositive_duration,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS TRUE
              AND has_nonpositive_distance IS TRUE
        ) AS valid_rows_with_nonpositive_distance,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS TRUE
              AND has_excessive_distance IS TRUE
        ) AS valid_rows_with_excessive_distance,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS TRUE
              AND has_invalid_amount IS TRUE
        ) AS valid_rows_with_invalid_amount,
        COUNT(*) FILTER (
            WHERE is_valid_completed_trip IS FALSE
              AND COALESCE(has_nonpositive_duration, FALSE) = FALSE
              AND COALESCE(has_nonpositive_distance, FALSE) = FALSE
              AND COALESCE(has_excessive_distance, FALSE) = FALSE
              AND COALESCE(has_invalid_amount, FALSE) = FALSE
        ) AS invalid_rows_without_quality_flag
    FROM stg_yellow_trips
),

checks AS (
    SELECT
        1 AS check_order,
        'Staging rows match raw January rows' AS check_name,
        staging_rows AS actual_value,
        raw_january_rows AS expected_value
    FROM staging_metrics
    CROSS JOIN raw_metrics

    UNION ALL

    SELECT
        2,
        'Valid plus invalid rows match staging rows',
        valid_rows + invalid_rows,
        staging_rows
    FROM staging_metrics

    UNION ALL

    SELECT 3, 'Rows with null validity classification', unclassified_rows, 0
    FROM staging_metrics

    UNION ALL

    SELECT 4, 'Staging rows outside January', rows_outside_january, 0
    FROM staging_metrics

    UNION ALL

    SELECT
        5,
        'Valid rows with nonpositive duration',
        valid_rows_with_nonpositive_duration,
        0
    FROM staging_metrics

    UNION ALL

    SELECT
        6,
        'Valid rows with nonpositive distance',
        valid_rows_with_nonpositive_distance,
        0
    FROM staging_metrics

    UNION ALL

    SELECT
        7,
        'Valid rows with distance above 500 miles',
        valid_rows_with_excessive_distance,
        0
    FROM staging_metrics

    UNION ALL

    SELECT
        8,
        'Valid rows with invalid amount',
        valid_rows_with_invalid_amount,
        0
    FROM staging_metrics

    UNION ALL

    SELECT
        9,
        'Invalid rows without a quality flag',
        invalid_rows_without_quality_flag,
        0
    FROM staging_metrics
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
