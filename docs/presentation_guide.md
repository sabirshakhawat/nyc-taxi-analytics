# Stakeholder presentation guide

## Decision and audience

Audience: fleet operations manager and dispatch lead. Ask them to approve the design of a limited coverage pilot using existing vehicles, conditional on recent-month validation and access to operating data. The desired business outcome is higher net earnings per working hour without worse service coverage. This project has not measured an improvement in revenue or profit.

## Suggested 10-minute presentation

1. **Business decision (1 minute).** Explain the proposed coverage pilot and ask whether dispatch data can support a fair comparison.
2. **Scope (1 minute).** 3,724,882 January pickups produce 3,517,775 eligible trips under the project's rules. These describe market activity, not a single company's book of business.
3. **Where and when (2 minutes).** Show the top-zone and hourly charts. The top 15 zones represent 45.8% of trips. Citywide pickups peak at 6 PM, but each zone has its own pattern.
4. **Priority windows (1 minute).** Use the new table. These averages include all 31 January days. They are screening inputs for selecting pilots, not recommendations to send a fixed number of drivers.
5. **Airport trade-off (1 minute).** JFK averages $79.27 per trip and 38.6 minutes. Other pickup zones average $26.56 and 16.3 minutes. Waiting time, empty travel and costs are absent, so profitability remains unknown.
6. **Unusual days (1 minute).** January 25 deserves investigation before permanent scheduling changes. Do not attribute the drop to weather or another event without evidence.
7. **Pilot decision (3 minutes).** Agree the owner, comparison shifts, data requirements and evaluation protocol. Leave time for questions about operational feasibility.

## Tableau presentation order

- **01 Demand overview:** four existing charts with reconciled data.
- **02 Coverage and airport decisions:** peak-window and airport comparison tables.
- **03 Pilot and measurement:** proposed experiment and decision gate.

Use the worksheet tabs to inspect chart details. These are three dashboard pages, not a Tableau Story object. The PowerPoint deck is the linear presentation version and includes editable charts, tables and speaker notes.

## Pilot measurement plan

| Measure | Definition | Additional data needed | Owner |
|---|---|---|---|
| Net earnings per working hour | Recorded operating receipts less agreed costs, divided by all working hours | Shift hours, receipts, fuel, toll treatment, fees and other agreed costs | Finance and operations |
| Trips per working hour | Completed trips divided by all working hours | Shift and trip linkage | Analytics |
| Empty miles | Distance driven without a passenger, compared on a consistent per-shift basis | Vehicle or dispatch telemetry | Dispatch |
| Passenger wait | Time from request to pickup, using consistent booking coverage | Request and pickup timestamps | Dispatch |
| Coverage safeguard | Service measures in both pilot and non-pilot areas | Dispatch and availability records | Operations |

Match weekday and shift duration between groups. Randomize where feasible. Otherwise document selection bias and adjust for weather and events. Agree the economically meaningful improvement threshold, minimum sample and service guardrails before the pilot begins. A four-week duration is a proposal, not proof of statistical sufficiency. Review uncertainty before expansion.

## Questions to anticipate

**Why not add more cars now?** Trip volume does not measure unmet demand. Existing supply may already be high.

**Why not focus only on airports?** Higher payment per trip can be offset by waiting, empty return travel and costs.

**Why not use passenger counts as a headline?** They are missing on 28.3% of eligible trips. Missing does not mean zero.

**Can we use this schedule throughout the year?** No. January is a single-month historical sample. Recheck recent months and weekday/weekend differences.

**Are the trips perfectly clean?** No. They pass explicit project rules. Residual errors and extreme values can remain, and no driver-level deduplication key is available in this analysis.

## After the meeting

Record the pilot sponsor, data owners, scope, comparison method and decision date. If the fleet cannot supply working hours and cost data, narrow the claim to observed pickup activity and postpone profitability recommendations.
