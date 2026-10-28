# Tableau presentation

Open **NYC Taxi Demand.twbx** in Tableau Public using **File > Open**.
The package includes six embedded Hyper extracts and their summary CSVs. No local DuckDB connection, raw Parquet or script run is needed to open it.

Do not reopen **Taxi Visualization** from Tableau's recent-files list: that original workbook references deleted temporary extracts and is not the repaired project copy.

If the old workbook is already open, leave it unchanged and open the package separately. Present the three dashboard tabs in order: **01 Demand overview**, **02 Coverage and airport decisions**, and **03 Pilot and measurement**. Four charts and two text-table worksheets support these pages. They are dashboard pages, not a native Tableau Story object.

The `.twb` is the editable source. Keep its adjacent `Data` folder intact if opening it directly. For sharing or downloading from GitHub, use the `.twbx` package.

To refresh from January source data, run `python scripts/build_stakeholder_package.py` from the project environment. It rebuilds SQL views, runs reconciliation and creates real extracts using Tableau's Hyper API. Do not use old CSV-only packages from earlier revisions. Narrative text describes January 2026 and requires editorial review if the reporting period changes.

Run `python scripts/validate_tableau_package.py` after rebuilding to check package wiring, embedded files, required extract attributes and dashboard references. These checks complement, rather than replace, a visual review in Tableau.
