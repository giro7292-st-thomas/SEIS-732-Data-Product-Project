#### 1. Working title

Storm Risks for State Hazard Mitigation Planners

#### 2. Audience and need

This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. A data product that summarizes event frequency, injuries, and damage done by storms over a recent 10-year window can help to accurately prioritize hazards which in turn might be used to target grant applications and apply funding towards the most frequent/deadly types of storms occuring in that state.

#### 3. Proposed Analytical Product and Questions

An interactive dashboard where the state planner selects their state, then sees hazard types ranked by severity (deaths, injuries, damage costs) with a peer-state comparison view (focusing on the midwest).

Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years?

How has the annual frequency and total reported damage for the top hazard changed from the first half to the later half of the 10-year window?

How does a state’s reported loss (per-capita) for a given hazard compare with a set of peer states?

#### 4. Source identification and access

Source data name and provider: Severe Storm Event Details | NOAA

Source URL: https://console.cloud.google.com/marketplace/product/noaa-public/severe-storm-events

Project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2015, storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Source approval and accessibility: Confirmed

Terms of service: This dataset is publicly available for anyone to use with no restrictions and is provided "AS IS" without any warranty, express or implied, from Google. Google disclaims all liability for any damages, direct or indirect, resulting from the use of the dataset.

#### 5. Quick source profile

Grain: One row equals one event record for one event type in one county over a time span.

Row Count:
| Table | Row Count |
|---|---:|
| storms_2015 | 87,155 |
| storms_2016 | 77,291 |
| storms_2017 | 81,655 |
| storms_2018 | 97,931 |
| storms_2019 | 102,613 |
| storms_2020 | 85,232 |
| storms_2021 | 83,083 |
| storms_2022 | 83,338 |
| storms_2023 | 91,312 |
| storms_2024 | 85,896 |
| storms_2025 | 93,203 |

Date Coverage: 2015-01-01T00:00:00 to 2025-12-31T23:59:00

Possible IDs or keys: event_id is the event key, episode_id appears to group related events. 

Fields likely to support the proposed questions: event_type, state, event_begin_time, injuries_direct, injuries_indirect, deaths_direct, deaths_indirect, damage_property, damage_crops, source

Important null, duplicate, type, or semi-structured characteristics: There are duplicate event_ids and episode_ids.

Refresh interval: Per the source, data about a specific event is added to the dataset within 120 days to allow time for damage assessments and other analysis.

#### 6. Need to source fit

| | Proposed question | Needed fields or concepts | Candidate source object(s) | Why the source appears sufficient | Gap or assumption to test in P1 |
|---|---|---|---|---|---|
| **Q1** | Which hazard types account for the largest share of deaths, injuries, and property and crop damage in each state over the last 10 years? | `event_type` (hazard), `state`, `event_begin_time` (date filter), `deaths_direct`, `deaths_indirect`, `injuries_direct`, `injuries_indirect`, `damage_property`, `damage_crops`. Shares need a per-state total as the denominator. | `bigquery-public-data.noaa_historic_severe_storms.storms_*` (2015-2025, 968,709 rows) | Every needed concept is in one table family. Checks show full date coverage, no null `event_id`s, and no rows in the wrong year table. Hazard, state, impact, and date fields are all present on each row. | 1. "Last 10 years" doesn't match the range: 2015-2025 is 11 calendar years, so decide whether to use 2016-2025 or keep 11 and say so.<br>2. 256,882 rows share an `event_id` with another row, so test whether impact fields are repeated before summing.<br>3. Null versus zero in damage and casualty fields may mean "not assessed" rather than "none," so profile both.<br>4. Decide whether to combine direct and indirect casualties.<br>5. Hurricane impacts are split across event types (surge, flood, wind), so shares by label won't equal shares by storm.<br>6. Check how `state` values are stored (case, territories, marine zones) so shares aren't split by label variants. |
| **Q2** | How has the annual frequency and total damage of the top hazard changed from the first half to the later half of the window? | Same fields as Q1, plus year derived from `event_begin_time`. A definition of "top hazard" (by event count, damage, or deaths), a defined event count, and a split point between the two halves. | `storms_*`, using the year tables or the date column to group by year. | The table has one row set per year, with row counts between about 77,000 and 103,000. No year is empty, and every year has the fields needed to compute annual counts and damage. | 1. Frequency has no direct field. Rows are not events, because `event_id` duplicates mean `COUNT(*)` and `COUNT(DISTINCT event_id)` give different answers, so pick a counting rule and test it.<br>2. An 11-year window has no even halves, so decide whether 2015-2020 vs. 2021-2025 or a 10-year version works.<br>3. 2024 and 2025 may be provisional, since NCEI adds and revises events with a lag. Check each table's last modified date.<br>4. Damage is nominal, not inflation-adjusted, and a few extreme events can dominate totals, so run an outlier check and consider reporting with and without them.<br>5. Reporting practices changed over time, so a change in counts may reflect more reporting rather than more events. |
| **Q3** | How does a state's per-capita loss for a given hazard compare with peer states? | Everything from Q1 for loss by state and hazard, plus a population figure per state (and probably per year), a definition of "loss" (property, crop, deaths, injuries), and a rule for choosing peer states. | `storms_*` for the numerator. The denominator isn't in this dataset, so it needs a second source such as Census population estimates (for example a public Census dataset in BigQuery or a downloaded file). | The numerator can be built from the same source as Q1. Only the population side needs something new. | 1. Population data has to be found, approved, and checked for coverage of 2015-2025, which is a new source for the project.<br>2. Join keys must match: `state` here is a text name and Census data may use FIPS codes or abbreviations, so test the match for all states.<br>3. Peer states need an explicit definition (region, size, hazard exposure), and the choice changes the result.<br>4. Small states can show extreme per-capita values from a single event, so check how stable the rates are.<br>5. Damage is nominal, so decide whether to adjust for inflation or compare within a single year.<br>6. Rows for marine zones or non-state areas may not map to a population, so test which rows drop out. |

