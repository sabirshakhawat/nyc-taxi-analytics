# NYC taxi coverage decisions

## Management takeaway

January 2026 yellow-taxi records suggest that a fleet could benefit from more flexible decisions about where drivers work and when shifts overlap. The opportunity is to test a schedule that follows observed pickup patterns, while measuring waiting time, empty driving, and earnings after costs. The records show completed trips; they do not establish where passengers could not find a taxi or where additional drivers would be profitable.

The analysis covers 3,517,775 trips that passed this project's quality rules. Those trips recorded $104.4 million in total trip amounts, averaging $29.68 per trip. These are recorded charges across the analyzed taxi market, not revenue or profit belonging to a particular company.

## Story point 1: Concentrate attention where customers already ride

**Use:** Top 15 Pickup Zones chart.

The 15 busiest pickup zones accounted for 1,611,413 trips—45.8% of all analyzed trips. Upper East Side South led with 152,530 trips, followed by Upper East Side North with 145,711. Manhattan accounted for 85.6% of pickups.

**Business implication:** A small group of locations deserves close operational attention. A fleet should compare its own presence in these areas with its completed trips and driver waiting times before expanding coverage.

**Action to test:** Pilot more driver availability in a few high-volume zones during their busy hours. Compare the results with similar shifts that retain the current schedule. Avoid moving the entire fleet based on historical volume alone: these zones may already have substantial taxi supply.

## Story point 2: A busy location is not busy at every hour

**Use:** Hourly-demand chart and selected-zone heatmap.

Across January, the 6–7 p.m. hour averaged about 7,408 pickups citywide, compared with about 889 during 4–5 a.m. The selected zones had different peak windows:

| Zone | Peak pickup window | Average trips in that hour per active day |
|---|---|---:|
| East Village | 11 p.m.–midnight | 265 |
| Upper East Side South | 3–4 p.m. | 393 |
| Midtown Center | 6–7 p.m. | 397 |
| JFK Airport | 8–9 p.m. | 361 |
| LaGuardia Airport | 2–3 p.m. | 215 |

An active day is a day with at least one recorded pickup in that zone-hour. These averages describe all analyzed taxis, not the number of trips one driver could complete. Citywide hourly figures above use the full 31-day month.

**Business implication:** A single location strategy for the entire day misses meaningful changes in pickup activity.

**Action to test:** Adjust shift overlaps and break schedules around the fleet's relevant peak windows. Offer drivers guidance on nearby pickup areas as patterns change through the day. Measure whether any extra trips compensate for the time and distance spent repositioning; the heatmap is not a prescribed route between these locations.

## Story point 3: Larger fares need to be weighed against time and costs

**Use:** Airport trip comparison table on the second Tableau dashboard page.

JFK ranked third in pickup trips with 141,612, but those trips recorded approximately $11.23 million in payments. Its average was $79.27 per trip, compared with $29.68 across all analyzed trips. JFK pickups also averaged about 38.6 minutes of trip time, versus 17.5 minutes overall.

**Business implication:** Airport work offers larger payments per trip, but a larger payment does not necessarily mean a more profitable shift. The data do not include the driver's full waiting time, empty return travel, or operating costs.

**Action to test:** Compare airport shifts with neighborhood shifts using earnings after costs per working hour. Include time waiting for the next passenger and driving without one. Use that evidence to decide the fleet's mix of airport and shorter urban trips.

## Story point 4: Build flexibility for unusually quiet days

**Use:** Daily-demand line chart. Point out January 25 during the presentation.

January 25 had 43,552 valid trips, about 62% fewer than the 115,420 trips on the previous Sunday, January 18. The decline was present before cleaning: source trips fell from 119,164 to 44,858. All 24 pickup hours were represented on both dates, and the rejected share was slightly lower on January 25.

This makes a surge in cleaning exclusions an unlikely explanation. It does not establish the external cause or prove that reporting was complete throughout each hour.

**Action to test:** Investigate the cause before making permanent scheduling changes. Develop a process for reviewing unusual declines and adapting shifts using current trip activity, driver reports, and relevant external conditions.

## Turn the findings into a measurable pilot

Run a proposed four-week pilot in a small number of zones and time windows, with comparable shifts retaining the existing schedule. Track completed trips per working hour, time without a passenger, empty miles, and earnings after costs per working hour. Track passenger waiting time if dispatch or booking records make it available. Account for differences in weekday, weather, events, and driver availability before attributing changes to the pilot.

Expand the approach only if it improves operating results without worsening service coverage. The proposed business change is more flexible deployment and a better balance of airport and neighborhood work; this analysis does not justify buying more vehicles or promise a specific profit increase.

## Scope and workbook note

Findings were recalculated from the project's current staging and enriched SQL using January 2026 source records. They describe one month of observed yellow-taxi activity, not year-round demand. Passenger counts are missing on 28.3% of valid trips, so passenger totals are not used as a headline measure.

The project package in `tableau/NYC Taxi Demand.twbx` contains three ordered dashboard pages: demand overview, coverage and airport decisions, and pilot measurement. It includes six embedded extracts and preserves the original user-saved workbook separately. The two presentation tables use the new priority-window and airport SQL analyses. The peak-window table includes all 31 calendar days in its denominator, unlike the original active-day heatmap.

See `presentation_guide.md` for the meeting flow and proposed measurement plan, and `metric_definitions.md` for definitions and limitations. No recommendation in this story represents a measured business improvement.
