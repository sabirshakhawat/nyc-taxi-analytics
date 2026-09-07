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
        WHERE tpep_dropoff_datetime < tpep_pickup_datetime
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
    ) AS no_pickupLocationID_count,

    COUNT(*) FILTER (
        WHERE DOLocationID IS NULL
    ) AS no_DOLocationID_count


FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')



