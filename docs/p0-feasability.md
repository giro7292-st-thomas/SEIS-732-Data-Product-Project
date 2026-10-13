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

Candidate tables and location: storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Source approval and accessibility: Confirmed

Terms of service: This dataset is publicly available for anyone to use with no restrictions and is provided "AS IS" without any warranty, express or implied, from Google. Google disclaims all liability for any damages, direct or indirect, resulting from the use of the dataset.

#### 5. Quick source profile

Grain: One row equals one event record for one event type in one county over a time span.

Row Count:
| Table | Row Count |
|---|---:|
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

Date Coverage: 2016-01-01T00:00:00 to 2025-12-31T23:59:00

Possible IDs or keys: event_id is the event key, episode_id appears to group related events. 

Fields likely to support the proposed questions: event_type, state, event_begin_time, injuries_direct, injuries_indirect, deaths_direct, deaths_indirect, damage_property, damage_crops, source

Important null, duplicate, type, or semi-structured characteristics: There are duplicate event_ids and episode_ids.

Refresh interval: Per the source, data about a specific event is added to the dataset within 120 days to allow time for damage assessments and other analysis.

#### 6. Need to source fit

| | Proposed question | Needed fields or concepts | Candidate source object(s) | Why the source appears sufficient | Gap or assumption to test in P1 |
|---|---|---|---|---|---|
| **Q1** | Which hazard types account for the largest share of deaths, injuries, and property and crop damage in each state over the last 10 years? | Yearly storm tables and `event_type`, `state`, `event_begin_time`, `deaths_direct`, `deaths_indirect`, `injuries_direct`, `injuries_indirect`, `damage_property`, `damage_crops` | `bigquery-public-data.noaa_historic_severe_storms.storms_*` (2016-2025, 968,709 rows) | All of the data is in one dataset. Reviewing the data shows full coverage, no null `event_id`s, and no rows in the wrong year table. Hazard, state, impact, and date fields are all on each row. | `event_id`s are duplicated, so test whether impact fields are repeated before summing.|
| **Q2** | How has the annual frequency and total damage of the top hazard changed from the first half to the later half of the window? | Same fields as Q1, plus year calculated from `event_begin_time`. A definition of top hazard, a defined event count, and a split point between the two halves. | `storms_` tables, using the year tables or the date column to group by year. | The table has one row set per year, no year is empty, and every year has the fields needed to compute annual counts and damage. | Frequency has no direct field: rows are not events, because of `event_id` duplicates a counting rule will need to be identified and tested. |
| **Q3** | How does a state's per-capita loss for a given hazard compare with peer states? | Everything from Q1 for loss by state and hazard, as well as a population number per state and year, a definition of loss, and a definition of peer states. | `storms_` tables for storm information. The state's populations are not in this NOAA dataset, so bring in Census population estimates. | The numerator can be built from the same source as Q1. Only the population needs something new. | Population data has to be found, approved, and checked for coverage of 2015-2025, which is a new source for the project.|

#### 7. Feasibility risks and response

##### A product idea that is too broad for the course timeline
The evidence that I currently have has clearly defined attributes for quantifying damage and injuries. The duplication of `event_id`s will require additional research and be the primary issue to resolve in P1. After better understanding the dataset, if the scope is too broad, the fallback option will be to eliminate Q3 and focus on Q1 and Q2. Additionally scope modification can be accomplished by reducing the national analysis to a 2-state comparison (MN vs. WI).

##### Insufficient grain, identifiers, date coverage, or descriptive context
Date coverage is solid, identifiers are weak, and grain is not simply one row per storm resulting in the potential for counting damage multiple times for a single storm. I will check whether damage is repeated across rows of the same `event_id` by comparing summed damage with the maximum single-row damage. Further, if the state values are messy, try to build a small mapping before computing any per-state share. The fallback is narrow the scope after defining the de-duplicating rule and limiting Q1 to direct deaths and direct property damage for the time frame.

#### 8. First P1 decision

##### Define the exact grain.

Find out what a repeated `event_id` represents; the de-duplicating rule will be determined once this is well understood.

#### 9. AI/tool accountability

AI was used to generate a variety of queries for exploring the data after the three proposed questions were drafted. Additionally, AI assisted with Markdown syntax, GitHub navigation, and version control processes.

