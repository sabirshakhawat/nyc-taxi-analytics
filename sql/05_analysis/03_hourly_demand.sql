-- Grain of the final result: one row per hour of day (0-23).
-- First aggregate each calendar date/hour so daily hourly averages are valid.
WITH demand_by_date_hour AS (
    SELECT
        pickup_date,
        EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
        COUNT(*) AS trips_in_hour,
        COUNT(passenger_count) AS trips_with_passenger_count,
        SUM(passenger_count) AS passengers_in_hour,
        SUM(fare_amount) AS metered_fares_in_hour,
        SUM(total_amount) AS passenger_amount_in_hour,
        SUM(trip_distance) AS distance_in_hour,
        SUM(trip_duration_minutes) AS duration_minutes_in_hour
    FROM enriched_yellow_trips
    GROUP BY
        pickup_date,
        pickup_hour
)

SELECT
    pickup_hour,
    COUNT(*) AS days_observed,

    SUM(trips_in_hour) AS total_trips,
    ROUND(AVG(trips_in_hour), 2) AS avg_daily_trips,

    SUM(passengers_in_hour) AS total_reported_passengers,
    ROUND(AVG(passengers_in_hour), 2) AS avg_daily_reported_passengers,
    ROUND(
        100.0 * SUM(trips_with_passenger_count) / SUM(trips_in_hour),
        2
    ) AS passenger_count_coverage_pct,

    ROUND(SUM(passengers_in_hour) * 1.0 / SUM(trips_with_passenger_count), 2)
        AS avg_passengers_per_reported_trip,

    ROUND(SUM(metered_fares_in_hour), 2) AS total_metered_fares,
    ROUND(AVG(metered_fares_in_hour), 2) AS avg_daily_metered_fares,

    ROUND(SUM(passenger_amount_in_hour), 2) AS total_passenger_amount,
    ROUND(AVG(passenger_amount_in_hour), 2) AS avg_daily_passenger_amount,
    ROUND(SUM(passenger_amount_in_hour) / SUM(trips_in_hour), 2)
        AS avg_passenger_amount_per_trip,

    ROUND(SUM(distance_in_hour) / SUM(trips_in_hour), 2)
        AS avg_trip_distance_miles,
    ROUND(SUM(duration_minutes_in_hour) / SUM(trips_in_hour), 2)
        AS avg_trip_duration_minutes
FROM demand_by_date_hour
GROUP BY pickup_hour
ORDER BY pickup_hour;
