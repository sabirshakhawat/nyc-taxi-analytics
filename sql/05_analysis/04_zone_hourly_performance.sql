CREATE OR REPLACE VIEW zone_hourly_demand AS
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
GROUP BY pickup_date, pickup_hour, pickup_borough, pickup_zone;

CREATE OR REPLACE VIEW zone_hourly_performance AS
WITH zone_hourly_demand_result AS (
    SELECT * FROM zone_hourly_demand
)
SELECT pickup_hour AS pickup_hour_of_the_day,
       pickup_zone,
       pickup_borough,
       ROUND(AVG(trips_in_hour)) AS avg_trips_per_active_day,
       ROUND(AVG(hourly_passenger_count)) AS avg_reported_passengers_per_active_day,
       ROUND(AVG(hourly_passenger_amount)) AS avg_passenger_amount_per_active_day,
       ROUND(AVG(hourly_trip_distance)) AS avg_trip_miles_per_active_day,
       ROUND(AVG(hourly_trip_duration_minutes)) AS avg_trip_minutes_per_active_day


FROM zone_hourly_demand_result
GROUP BY pickup_hour_of_the_day,pickup_borough,pickup_zone
ORDER BY pickup_hour,avg_trips_per_active_day DESC, pickup_zone;

SELECT * FROM zone_hourly_performance
ORDER BY pickup_hour_of_the_day, avg_trips_per_active_day DESC, pickup_zone;

/*
    Overview on zone hour grain performance: passengers picked up,
    fares collected, trip distance.

    UES at 3PM has the highest hourly pickup demand, with 413 trips 
    per day on avg during that hour.

    Upper East Side zones produced the strongest afternoon demand. 
    Upper East Side South led at 1, 2, and 4 p.m., 
    while Upper East Side North reached the overall peak at 3 p.m.

    Midtoen becomes the leading pickup zone from 5-7 PM, due to 
    people getting off at work. Peaking at 400 average trips at 6 PM.

    East Village led overnight demand from midnight through 4 AM.
    Demand dropped from 254 trips at midnight to 64 trips at 4 AM.

    JFK led at 6 AM, 8 PM, 10 PM and 11 PM.


*/



