# NYC Taxi Business Intelligence Platform

## Project Overview

This project analyzes NYC Yellow Taxi trip data to identify revenue trends, high-demand locations, operational patterns, and opportunities for improved driver allocation.

The project is designed as a SQL-first business intelligence workflow. DuckDB is used to query NYC Taxi and Limousine Commission Parquet files, transform raw trip records into analytical models, and produce datasets for a future Tableau or Power BI dashboard.

## Business Scenario

A transportation company has asked its data analyst to determine:

- Where taxi demand is highest
- Which locations and routes generate the most revenue
- How demand changes by time and day
- Which trips may contain data-quality problems
- Where additional driver availability may be needed

## Planned Technology

- SQL
- DuckDB
- Python
- Git and GitHub
- NYC TLC Parquet data
- Tableau or Power BI

## Running the analysis and validation

Run commands from the project root. The SQL files in `sql/05_analysis/` now
create DuckDB views and then select from them, so they both register the
reporting objects and show results. Run the files in this order:

1. `sql/02_staging/01_clean_trips.sql`
2. `sql/03_models/01_enriched_trips.sql`
3. All five files in `sql/05_analysis/`, in numeric order
4. The corresponding files in `sql/04_quality/`

For example:

```sh
.venv/bin/python scripts/run_sql.py sql/05_analysis/01_daily_demand_revenue.sql
.venv/bin/python scripts/run_sql.py sql/04_quality/03_reconcile_daily_demand.sql
```

After editing an analysis SQL file, rerun that file to replace its saved view
definition before running reconciliation. The zone-hour and route analysis files
also create unrounded intermediate views used to validate their displayed
averages. Reconciliation reads the same analysis views used for reporting;
expected totals still come independently from `enriched_yellow_trips`.
