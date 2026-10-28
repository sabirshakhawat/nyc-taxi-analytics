-- Mutually exclusive pickup segments, defined by TLC location IDs.
-- "Other pickup zones" includes every eligible trip outside JFK and LGA.
-- Recorded payment is total_amount, not profit or earnings per working hour.
CREATE OR REPLACE VIEW airport_comparison AS
SELECT CASE WHEN PULocationID = 132 THEN 'JFK Airport'
            WHEN PULocationID = 138 THEN 'LaGuardia Airport'
            ELSE 'Other pickup zones' END AS pickup_segment,
       COUNT(*) AS total_trips,
       ROUND(AVG(total_amount), 2) AS avg_recorded_payment_usd,
       ROUND(AVG(trip_duration_minutes), 2) AS avg_trip_minutes,
       ROUND(AVG(trip_distance), 2) AS avg_trip_miles,
       ROUND(SUM(total_amount), 2) AS total_recorded_payment_usd
FROM enriched_yellow_trips
GROUP BY pickup_segment;

SELECT * FROM airport_comparison ORDER BY pickup_segment;
