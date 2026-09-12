CREATE OR REPLACE VIEW stg_yellow_trips AS (

        WITH flagged_trips AS (
        SELECT *,
        CAST ((tpep_dropoff_datetime-tpep_pickup_datetime) AS VARCHAR) 
        AS trip_duration_hms,
        ROUND(DATE_DIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) / 60.0,2) 
        AS trip_duration_minutes,
        CASE
            WHEN tpep_dropoff_datetime <= tpep_pickup_datetime 
            THEN TRUE ELSE FALSE
            END AS has_nonpositive_duration,
        CASE
            WHEN trip_distance <= 0
            THEN TRUE ELSE FALSE
            END AS has_nonpositive_distance, 
        CASE
            WHEN trip_distance>500      
            THEN TRUE ELSE FALSE
            END AS has_excessive_distance,
            -- A 500-mile ceiling removes the extreme data-error cluster.
            -- The largest remaining observed trip is 295.99 miles;
            -- the next recorded distance is 3,687.45 miles.
        CASE 
            WHEN total_amount <=0 OR fare_amount < 0
            THEN TRUE ELSE FALSE
            END AS has_invalid_amount

            FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')
            WHERE tpep_pickup_datetime >= TIMESTAMP '2026-01-01' 
            AND tpep_pickup_datetime < TIMESTAMP '2026-02-01'
)
        SELECT *,
        CASE    
            WHEN has_invalid_amount=TRUE OR has_nonpositive_duration = TRUE
            OR has_nonpositive_distance = TRUE 
            OR has_excessive_distance=TRUE
            THEN FALSE ELSE TRUE
            END AS is_valid_completed_trip
        FROM flagged_trips
)



