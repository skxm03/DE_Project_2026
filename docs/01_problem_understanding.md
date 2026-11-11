# CP1 · Problem understanding

The Google Maps Navigation database supports place discovery, saved lists, live traffic and trip history. We need to rebuild it from the 11 CSV exports so these features return useful results and the team can measure the supplied workload.

| Problem | What needs to work and for whom | Priority | Queries |
|---|---|---|---|
| P1 · Place search | Travellers need quick results by location, name or Plus Code. The search team needs “open now” to account for places that stay open past midnight. | Customer-facing / real-time | R01, R03, R04, R23 |
| P2 · Place pages and saved lists | Travellers need details, hours, recent reviews and saved places to load quickly. Reviewers and Local Guides need responsive review and save actions. | Customer-facing / real-time | R02, R05, R06, W02, W03 |
| P3 · Live traffic | Drivers need current speed and incident information. The traffic team needs the map refreshed every minute, with expired incidents cleared. | Customer-facing / real-time | R07, R08, R10, W05 |
| P4 · Traffic history | The traffic and road-safety teams need hourly speed patterns and the share of readings above posted limits. | Reporting / analytics | R09, R25 |
| P5 · Routing and ETA | Drivers need navigation to start promptly. The routing team needs to compare predicted and actual durations and see trip trends, rerouting hotspots and cancellation rates. | Real-time: W01; reporting: R11, R12, R17, R18 | R11, R12, R17, R18, W01 |
| P6 · Unused origins | The data team needs a reliable list of places never selected as a trip origin. Trips started from GPS can have a NULL origin place, which can make the supplied `NOT IN` query return no rows. | Reporting / analytics | R13 |
| P7 · Listing quality | The data quality team needs to find stale rating summaries, trips to closed listings, missing hours and likely duplicates. Business owners and travellers rely on accurate listings. | Reporting / analytics | R15, R16, R21, R24, W04 |
| P8 · Community and usage | Community, moderation and analytics teams need usable guide rankings, review queues, hospital activity and daily trip reports as trip volume grows toward 20×. | Real-time internal screen: R22; reporting: R14, R19, R20 | R14, R19, R20, R22 |

**Assumptions.** Weekly opening hours use local India time; an interval can continue into the next day. A trip can start from GPS without a named origin and can be anonymous. CP1 uses the supplied exports and leaves the workload unchanged for baseline measurement. The 20× figure is a future test target.
