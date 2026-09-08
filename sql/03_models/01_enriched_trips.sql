CREATE OR REPLACE VIEW enriched_yellow_trips AS (
    SELECT
    trips.*,
    pickup.Zone AS pickup_zone,
    pickup.Borough AS pickup_borough,
    dropoff.Zone AS dropoff_zone,
    dropoff.Borough AS dropoff_borough, 
    CAST(trips.tpep_pickup_datetime AS DATE) AS pickup_date
FROM stg_yellow_trips AS trips

LEFT JOIN read_csv('data/reference/taxi_zone_lookup.csv') AS pickup
    ON trips.PULocationID = pickup.LocationID

LEFT JOIN read_csv('data/reference/taxi_zone_lookup.csv') AS dropoff
    ON trips.DOLocationID = dropoff.LocationID

WHERE trips.is_valid_completed_trip = TRUE
)






    