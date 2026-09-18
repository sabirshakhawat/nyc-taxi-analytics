
CREATE OR REPLACE VIEW daily_demand_revenue AS
SELECT pickup_date,
           COUNT(*) AS daily_trip_count,
           SUM(fare_amount) AS total_metered_fares,
           SUM(total_amount) AS total_passenger_amount_paid,
           SUM(passenger_count) AS total_passengers,
           AVG(passenger_count) AS avg_passenger_amount

FROM enriched_yellow_trips
GROUP BY pickup_date;

SELECT * FROM daily_demand_revenue ORDER BY pickup_date;
