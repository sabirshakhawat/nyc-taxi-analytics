SELECT 
COUNT(*) as total_rows,
COUNT (*) FILTER (
    WHERE (tpep_pickup_datetime) < TIMESTAMP '2026-01-01'
    ) AS trips_before_january,
COUNT (*) FILTER (
    WHERE (tpep_pickup_datetime) >= TIMESTAMP ' 2026-02-01'
) AS trips_after_january,
COUNT(*) FILTER(
    WHERE (tpep_pickup_datetime)>= TIMESTAMP '2026-01-01' AND 
    (tpep_pickup_datetime) < TIMESTAMP '2026-02-01'
) AS valid_january_trips

FROM read_parquet('data/raw/yellow_tripdata_2026-01.parquet')