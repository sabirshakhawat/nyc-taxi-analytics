SELECT 
COUNT() AS total_trips,
MIN(tpep_pickup_datetime) AS earliest_pickup,
MAX(tpep_pickup_datetime) AS latest_pickup, 
ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
ROUND(AVG(total_amount), 2) AS avg_amount


FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')
