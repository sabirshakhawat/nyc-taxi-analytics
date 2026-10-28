# Metric definitions and limitations

Source: [NYC TLC trip records](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), January 2026 yellow taxi Parquet and taxi zone lookup. TLC obtains these records from technology providers and does not guarantee their accuracy. Snapshot values are in `analysis_evidence.json`.

| Metric | Grain and calculation | Interpretation |
|---|---|---|
| Eligible trips | One trip row after the staging validity filter and zone enrichment | Project-defined eligible recorded trips |
| Daily trips | Pickup date, count of eligible rows | All pickup zones combined |
| Citywide average trips in hour | Hour of day, average date-hour count | All 31 dates are observed for each hour in this snapshot |
| Zone-hour heatmap | Zone and hour, average over dates with one or more trips | Excludes zero-trip days; may overstate all-calendar-day activity |
| Priority peak-hour average | Top-five zone and its busiest hour, hour total / 31 | Includes zero-trip days and breaks tied peak hours by earliest hour |
| Monthly zone trip share | Zone trip count / all eligible trips | Share of observed January activity |
| Recorded payment | `total_amount`, USD | Total recorded amount, including applicable components; cash tips may not be captured. Not net revenue or profit |
| Average trip duration | Mean `trip_duration_minutes`, from pickup to drop-off | Excludes waiting before pickup and empty travel between jobs |
| Airport segments | JFK pickup ID 132, LGA ID 138, all other pickup IDs | Mutually exclusive, including all eligible trips |

## Eligibility rules

January pickups use a half-open boundary, from 2026-01-01 inclusive to 2026-02-01 exclusive. Staging flags drop-off at/before pickup, distance at/below zero, distance above 500 miles, total amount at/below zero, or negative base fare. Enrichment retains trips whose `is_valid_completed_trip` flag is true. The 500-mile cap is an analyst rule, not a TLC rule. SQL comparisons with NULL do not automatically flag NULL values under the current CASE logic, so separate validation is essential. No upper duration threshold or general duplicate-removal rule is applied.

## Interpretation boundaries

The analysis is descriptive. It cannot quantify unserved requests, market-wide supply, driver working hours, costs, waiting time or causal profit uplift. A high-volume zone is not necessarily underserved. Market-wide payment totals are not revenue owned by one fleet. Single-month patterns require confirmation in additional months.

The presentation tables are formatted snapshot rows for readability. Their numeric evidence and reproducible SQL remain available in `sql/05_analysis/06_priority_windows.sql`, `07_airport_comparison.sql` and `analysis_evidence.json`.
