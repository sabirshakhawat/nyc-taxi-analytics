
SELECT pickup_date,
           COUNT(*) AS daily_trip_count,
           ROUND(SUM(fare_amount)) AS total_metered_fares,
           ROUND(SUM(total_amount)) AS total_passenger_amount_paid,
           SUM(passenger_count) AS total_passengers,
           ROUND(AVG(passenger_count), 2) AS avg_passenger_amount

FROM enriched_yellow_trips
GROUP BY pickup_date


