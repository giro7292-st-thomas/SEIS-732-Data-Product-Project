#### 1. Establish the question and check the source

Audience and Need: This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. A data product that summarizes event frequency, injuries, and damage done by storms over a recent 10-year window can help to accurately prioritize hazards which in turn might be used to target grant applications and apply funding towards the most frequent/deadly types of storms occuring in that state.

Primary Question: Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years?

P0 Changes: I am dropping Q3, 'How does a state’s reported loss (per-capita) for a given hazard compare with a set of peer states?', per feedback, and focusing on Q1 (above).

Source objects project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Source Row Meaning: Each source row is a location for one storm event. Events with a single location have one row, and events with several points repeat across several rows. The event’s details, deaths, injuries, and damage are copied into each of its rows, so they describe the whole event, not that specific point.

Source Size and Date Coverage:
| Year | Rows | First event | Last event | Size (MB) |
|:-----|-----:|:------------|:-----------|----------:|
| 2016 | 77,291 | 2016-01-01 00:00 | 2016-12-31 23:15 | 16.4 |
| 2017 | 81,655 | 2017-01-01 00:00 | 2017-12-31 23:23 | 17.6 |
| 2018 | 97,931 | 2018-01-01 00:00 | 2018-12-31 23:30 | 20.8 |
| 2019 | 102,613 | 2019-01-01 00:00 | 2019-12-31 23:50 | 21.8 |
| 2020 | 85,232 | 2020-01-01 00:00 | 2020-12-31 22:30 | 18.1 |
| 2021 | 83,083 | 2021-01-01 00:00 | 2021-12-31 23:56 | 16.9 |
| 2022 | 83,338 | 2022-01-01 00:00 | 2022-12-31 23:30 | 15.9 |
| 2023 | 91,312 | 2023-01-01 00:00 | 2023-12-31 05:35 | 17.4 |
| 2024 | 85,896 | 2024-01-01 00:00 | 2024-12-31 23:30 | 16.5 |
| 2025 | 93,203 | 2025-01-01 00:00 | 2025-12-31 23:40 | 18.4 |
| **All years** | **881,554** | **2016-01-01 00:00** | **2025-12-31 23:40** | **179.8** |

Candidate Identifiers: `event_id` combined with `location_index` uniquely identifies each source row. `event_id'  will be the key once the data is deduplicated to one row per event. `state_fips_code` combined with `event_type` will be used as identifiers for the analysis output.

Data Issue or Restriction: Deaths, injuries, and damage are repeated for events with multiple location rows. Summing these facts from the source table would be an artificial inflation. Deduplicating to one row per `event_id` before aggregating fixes this. Also, `state` is ambiguous ("Ar" could be Arizona or Arkansas), so `state_fips_code` is used as the state key.

Focused Source Profile:
| Year | Source rows | Fact rows | Rows removed |
|:-----|------------:|----------:|-------------:|
| 2016 | 77,291 | 56,005 | 21,286 |
| 2017 | 81,655 | 57,041 | 24,614 |
| 2018 | 97,931 | 62,699 | 35,232 |
| 2019 | 102,613 | 67,864 | 34,749 |
| 2020 | 85,232 | 61,281 | 23,951 |
| 2021 | 83,083 | 61,389 | 21,694 |
| 2022 | 83,338 | 69,887 | 13,451 |
| 2023 | 91,312 | 75,593 | 15,719 |
| 2024 | 85,896 | 69,801 | 16,095 |
| 2025 | 93,203 | 72,360 | 20,843 |
| **All years** | **881,554** | **653,920** | **227,634** |

Conclusion:

The fact grain is one row per storm event, identified by `event_id`; one hazard type in one county, forecast zone, or marine zone within one state, with its deaths, injuries, and damage recorded once.

The source tables are stored with one row per location point, so the fact is built with a selection rule that keeps one row per `event_id`. The fact grain is confirmed by Check 7, showing the fact contains 653,920 rows that matches the 653,920 distinct events of the source. Since casualties and damage are recorded to the hazard and county where they happened, summing fact rows by `state_fips_code` and `event_type` will result in each state's impact by hazard type while avoiding duplicate counting across counties, states, or hazard types.

#### 2. Define the model and predict a history consequence

Business Process: Storm event reporting from the NOAA where significant weather events are recorded along with the number of deaths, injuries, and damage that the event caused.

Fact-table Type: Transaction fact table. Each row is one recorded event, and every measure is additive across hazard, place, and time.

Fact-table Grain: One row represents one NOAA-reported storm event; a single event type in a single forecast zone, starting at a single time, identified by NOAA's event_id.

Consequential Modelling Choice: By choosing event-grain, and not location-point grain, the storm event damage, injury, and death data can safely be added. The tradeoff is that location information is lost - if this information were to be used in GIS, tornado paths could not be correctly mapped. This decision is acceptable for the selected question that is working at a state-level scale.

```mermaid
erDiagram
    DIM_DATE ||--o{ FACT_STORM_EVENT : "event begin date"
    DIM_STATE ||--o{ FACT_STORM_EVENT : "occurs in"
    DIM_HAZARD ||--o{ FACT_STORM_EVENT : "classified as"

    FACT_STORM_EVENT {
        string event_id PK "NOAA source ID; degenerate dimension"
        string episode_id "NOAA source ID; degenerate dimension"
        int date_key FK "YYYYMMDD of event begin date"
        string state_key FK "State FIPS code"
        int hazard_key FK "Warehouse surrogate key"
        string cz_type "C county, Z zone, or M marine"
        string cz_fips_code "County or zone code"
        int deaths_direct "Additive measure"
        int deaths_indirect "Additive measure"
        int injuries_direct "Additive measure"
        int injuries_indirect "Additive measure"
        numeric damage_property "Additive measure, USD"
        numeric damage_crops "Additive measure, USD"
    }

    DIM_DATE {
        int date_key PK "YYYYMMDD"
        date full_date
        int year
        int quarter
        int month
    }

    DIM_STATE {
        string state_key PK "State FIPS"
        string state_name "Requires FIPS lookup"
        string state_abbr
    }

    DIM_HAZARD {
        int hazard_key PK "Warehouse surrogate key"
        string event_type
        string event_group "OPTIONAL: My own grouping interpretation, ex: heavy snow and lake-effect snow"
    }
```

Tracing Modelling Question:

The primary question I am analyzing asks which hazard types account for the most deaths, injuries, and damage (property and crop) in each state from 2016 to 2025. The `FACT_STORM_EVENT` helps to answer this as each row is one storm event with the impacts counted only once so the measures related to deaths, injuries, and damage can be summed. The fact table is joined to `DIM_DATE` via the event start date, where a filter is applied for 2016 through 2025. It is also joined to `DIM_STATE` via the FIPS code, and joined to `DIM_HAZARD` which supplies information about the event through the `event_type` field. `event_group` is a potential method to group the events together for easier product consumption by reducing the amount of similar hazards to those that are related - this would be calculated via a CASE statement. In summary, each measure is summed by state and hazard type which will then be ranked to determine which is responsible for the largest quantity of deaths, injuries, and damage.

History Decision:
`event_type` is the attribute that is most likely to change (or be reclassified); NOAA may change spelling, naming, split a hazard into two type, or group hazards together overtime as climate change shifts standard hazard behaviors and classifications. This is where the `event_group` attribute would be used and treated as Type 1. For example, if `lake-effect snow` changed to `lake effect snow`, it would be overwritten using the SQL below. Treating this as Type 1 can have a direct impact on the primary analytical question by changing the hazard ranking; adding a new heat-related hazard could potentially group it with other heat-related hazards, combining deaths that would have previously been split across different labels, thus moving `Heat`'s ranking higher. I've decided on Type 1 as each year should be classified under the current definitions; each year added to the analysis would need to have unique values checked, grouped as needed, and have the grouping changes documented in the procedures.

The small behavior I can test by P3 is applying hazard groupings to the list of hazards, and document which values are grouped into a new hazard type.

```
CASE
  WHEN LOWER(TRIM(event_type)) IN ('lake-effect snow', 'lake effect snow') THEN 'Snow'
  ELSE INITCAP(event_type)
END AS event_group
```

#### 3. Plan the build and its checks

Raw, Curated, and Serving objects:

| Layer | Object | What it does |
|:------|:-------|:-------------|
| Raw | `raw_storm_events` | Reads `storms_2016` to `storms_2025` source tables through a `storms_*` wildcard with no changes. Keeps the source grain. |
| Curated | `dim_date` | One row per calendar date, 2016 to 2025. |
| Curated | `dim_state` | One row per state FIPS code, with name and abbreviation coming from the Census lookup. |
| Curated | `dim_hazard` | One row per distinct normalized `event_type`. |
| Curated | `fact_storm_event` | Appliy the selection rule and adds `date_key`, `state_key`, and `hazard_key`, and keeps the casualty and damage measures. |
| Serving | `srv_state_hazard_shares` | One row per state and `event_group`, with summed deaths, injuries, property damage, and crop damage, and its rank within the state. |
| Serving | `srv_state_top_hazards` | The top hazard for each state and measure for the hazard planner summary. |

Preliminary Run Order:

1. Create raw_storm_events view, check it returns 881,554 rows.
2. Build dim_date, dim_state, and dim_hazard and confirm each key is unique and every source label maps to a hazard.
3. Build fact_storm_event. Confirm it has 653,920 rows which matches distinct source events, no repeated event_id, and no keys missing from their dimensions.
4. Build srv_state_hazard_shares. Check that shares add up to 100% within each state and measure.
5. Build srv_state_top_hazards. Check there’s one row per state and measure - review ties if needed.

Trace of One Measure: `deaths_direct`

| Stage | Object | Form of `deaths_direct` | Transformation |
|:------|:-------|:------------------------|:---------------|
| Source | `storms_*` | Deaths for one event. Repeated for each of the location rows | None |
| Raw | `raw_storm_events` | Same as source. | None |
| Curated | `fact_storm_event` | Deaths counted once per event | Selection rule keeps one row per `event_id`.The event is linked to its state via FIPS, its hazard via the normalized label, and the date through the begin date |
| Serving | `srv_state_hazard_shares` | Total deaths per state and hazard group | Filtered to 2016 to 2025, summed up by `state_key` and `event_group`, and divided by the state's total deaths. A rank is applied. |


#### 4. Diagnose and revise the plan
