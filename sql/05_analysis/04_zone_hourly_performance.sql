WITH zone_hourly_demand AS (
    SELECT pickup_date,
           EXTRACT('hour' FROM tpep_pickup_datetime) AS pickup_hour,
           COUNT(*) AS trips_in_hour,
           pickup_borough, 
           pickup_zone, 
           SUM(passenger_count) AS hourly_passenger_count,
           SUM(total_amount) AS hourly_passenger_amount,
           SUM(trip_distance) AS hourly_trip_distance,
           SUM(trip_duration_minutes) AS hourly_trip_duration_minutes
    FROM enriched_yellow_trips
    GROUP BY pickup_date,pickup_hour,pickup_borough,pickup_zone
)
SELECT pickup_hour,
       pickup_zone,
       pickup_borough,
       ROUND(AVG(trips_in_hour)) AS zone_avg_trips_in_hour,
       ROUND(AVG(hourly_passenger_count)) AS avg_hourly_passenger_count,
       ROUND(AVG(hourly_passenger_amount)) AS avg_hourly_passenger_amount,
       ROUND(AVG(hourly_trip_distance)) AS avg_hourly_trip_distance,
       ROUND(AVG(hourly_trip_duration_minutes)) AS avg_hourly_trip_duration_minutes


FROM zone_hourly_demand
GROUP BY pickup_hour,pickup_borough,pickup_zone
ORDER BY pickup_hour,zone_avg_trips_in_hour DESC, pickup_zone

/*
    Overview on zone hour grain performance: passengers picked up,
    fares collected, trip distance,




