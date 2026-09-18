CREATE OR REPLACE VIEW zone_performance AS
SELECT 
       COUNT(*) AS daily_trip_count,
       pickup_zone,
       pickup_borough,
       ROUND(SUM(fare_amount),2) AS total_metered_fares,
       ROUND(SUM(total_amount)) AS total_passenger_amount_paid,
       SUM(passenger_count) AS total_passengers,
       ROUND(AVG(passenger_count), 2) AS avg_passenger_per_trip

FROM enriched_yellow_trips
GROUP BY pickup_zone,pickup_borough
ORDER BY daily_trip_count DESC;

SELECT * FROM zone_performance ORDER BY daily_trip_count DESC;

-- UES,JFK, Midtown areas have the highest concentration of total trips
-- most trips happening in Manhattan.
--JFK pickup zones make the most money because riders are going to 
--manhattan which is a longer distance on top of the surcharge.
-- JFK also doesn't have the most amount of trips departing from it
-- but it has the highest amount of passengers driven from it.
