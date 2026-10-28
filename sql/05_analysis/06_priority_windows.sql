-- One row per top-five pickup zone. Rank by January eligible trip count.
-- Divide hour totals by all 31 calendar days, including days with zero trips.
-- Earliest hour wins a tie. This is a planning signal, not unmet demand.
CREATE OR REPLACE VIEW priority_windows AS
WITH zones AS (
    SELECT PULocationID AS pickup_location_id, pickup_zone,
           COUNT(*) AS monthly_trips,
           ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, PULocationID) AS zone_rank
    FROM enriched_yellow_trips
    GROUP BY PULocationID, pickup_zone
), hours AS (
    SELECT PULocationID AS pickup_location_id,
           EXTRACT(HOUR FROM tpep_pickup_datetime)::INTEGER AS pickup_hour,
           COUNT(*) AS trips,
           ROW_NUMBER() OVER (
               PARTITION BY PULocationID
               ORDER BY COUNT(*) DESC, EXTRACT(HOUR FROM tpep_pickup_datetime)
           ) AS peak_rank
    FROM enriched_yellow_trips
    GROUP BY PULocationID, EXTRACT(HOUR FROM tpep_pickup_datetime)
)
SELECT z.zone_rank, z.pickup_location_id, z.pickup_zone,
       h.pickup_hour AS peak_hour,
       ROUND(h.trips / 31.0, 2) AS avg_peak_hour_trips_per_calendar_day,
       z.monthly_trips,
       ROUND(100.0 * z.monthly_trips /
             (SELECT COUNT(*) FROM enriched_yellow_trips), 2) AS monthly_trip_share_pct
FROM zones z JOIN hours h USING (pickup_location_id)
WHERE z.zone_rank <= 5 AND h.peak_rank = 1;

SELECT * FROM priority_windows ORDER BY zone_rank;
