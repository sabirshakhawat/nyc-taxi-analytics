CREATE OR REPLACE VIEW route_performance AS
    SELECT pickup_zone,
           dropoff_zone,
           COUNT(*) AS route_total_trips,
           SUM(total_amount) AS route_total_amount,
           SUM(trip_duration_minutes) AS route_total_trip_duration,
           SUM(trip_distance) AS route_total_trip_distance,
           CASE 
                WHEN PULocationID = DOLocationID 
                THEN 'Same-Zone'
                ELSE 'Cross-Zone'
                END AS route_category

    FROM enriched_yellow_trips
    GROUP BY pickup_zone,dropoff_zone,route_category;

CREATE OR REPLACE VIEW route_analysis AS
SELECT pickup_zone,
       dropoff_zone,
       route_category,
       route_total_trips,
       ROUND((route_total_amount)/route_total_trips, 2) AS avg_route_amount,
       ROUND((route_total_trip_distance)/route_total_trips, 2) AS avg_route_trip_distance,
       ROUND((route_total_trip_duration)/route_total_trips) AS avg_route_trip_duration

FROM route_performance
ORDER BY route_total_trips DESC;

SELECT * FROM route_analysis ORDER BY route_total_trips DESC;
