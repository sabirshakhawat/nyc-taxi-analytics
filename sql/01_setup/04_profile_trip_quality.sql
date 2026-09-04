-- Goal: profile suspicious or incomplete trip records before deciding
-- which records should be filtered, retained, or flagged.

-- Count every row in the source data.
SET file_search_path ='/Users/sabir/Documents/data-analyst-projects/nyc-taxi-analytics';


SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE tpep_pickup_datetime IS NULL
    ) AS no_pickup_count,

    COUNT(*) FILTER (
        WHERE tpep_dropoff_datetime IS NULL
    ) AS no_dropoff_count, 

    COUNT(*) FILTER (
        WHERE tpep_dropoff_datetime = tpep_pickup_datetime
    ) AS zero_trip_duration_count, 

    COUNT(*) FILTER (
        WHERE tpep_dropoff_datetime <= tpep_pickup_datetime
    ) AS negative_trip_duration_count,

    COUNT(*) FILTER (
        WHERE trip_distance <=0
    ) AS trip_dist_0_or_neg_count,

    COUNT(*) FILTER (
        WHERE fare_amount < 0
    ) AS negative_fare_count, 

    COUNT(*) FILTER (
        WHERE total_amount< 0
    ) AS neg_total_amount_count,    

    COUNT(*) FILTER (
        WHERE PULocationID IS NULL
    ) AS no_pickupLocationID_count


FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')

-- Count records with a negative total amount.

-- Count records with no pickup location ID.

-- Count records with no drop-off location ID.

-- Read from the January 2026 Yellow Taxi Parquet file.

-- Hints:
-- 1. Return all metrics in one row with conditional aggregation.
-- 2. COUNT(*) FILTER (WHERE ...) can count rows matching one condition.
-- 3. Missing values require IS NULL rather than = NULL.
-- 4. Use <= 0 when both zero and negative values are suspicious.
-- 5. Use < 0 when only negative values are suspicious.

