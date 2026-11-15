#### 1. Establish the input and run ingestion

Audience, primary analytical question, and changes from P1: This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years? No changes to P1 source or grain.

Source Data:

Source objects project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Raw input and preservation:

The raw table that I am creating keep every source column and row preserved. As a result, this includes repeated event quantities on each location row; raw does not deduplicate or filter any data. Two fields are added, `source_year` and `loaded_at` which help as multiple years worth of data are combined into a single table and adds metadata as to when the Source->Raw ingestion was ran.

Last Run: 2026-11-09 00:44:53.245406 UTC

Rows in Raw: 881,554 (P1 expectation: 881,554)

One raw row is equal to one location of one NOAA storm event as identified by `event_id` and `location_index`. As identified in P1, a missing location_index indicates an event with a single location.

Reproducibility limits: The public dataset appears to not have any indication of versioning for if/when storm event measures are modified.

See `02_ingest.sql` for running ingestion.

#### 2. Build Curated at the intended grain

See `03_curate.sql` for building curated tables.

| Object | One row represents | Row identifier | Rows |
|:-------|:-------------------|:---------------|-----:|
| `dim_date` | One calendar date, 2016-01-01 to 2025-12-31 | `date_key` (YYYYMMDD) | 3,653 |
| `dim_state` | One state, DC, territory, or NOAA marine/other FIPS code | `state_key` (2-digit FIPS) | 74 |
| `hazard_map` | One version of an `event_type` label's grouping | `map_key`; one `is_current` row per `event_type` | 54 |
| `fact_storm_event` | One NOAA storm event: one hazard type in one county/zone, starting at one time | `event_id` | 653,920 |

Rules applied:
- Repeated rows (selection rule): Raw has one row per event location, so a multi-location event repeats counts and dollars of deaths, injuries, and damage on every row. The fact keeps one row per `event_id`.
- Non-state FIPS: NOAA uses FIPS codes for marine zones and other areas that are not a U.S state. These codes are added to `dim_state` as `OTHER` rather than being dropped, so every fact row keeps a valid state key. The audience output will filter to `STATE` and `DC` (`dim_state`).
- Relationships: The fact table joins to current hazard mapping on `event_type`. `hazard_map` has one current row per label, so the join will not add rows. Unmapped labels still show up as a null `hazard_key` instead of the event being dropped from the LEFT JOIN.

| Step | Rows | How it is derived |
|:-----|-----:|:------------------|
| Raw input | 881,554 | All location rows, 2016–2025 |
| Rows from multi-location events | 311,013 | 83,379 events with more than one location row |
| Rows removed by the selection rule | 227,634 | 311,013 − 83,379 (one row kept per event) |
| Curated fact | 653,920 | 881,554 − 227,634; equals distinct `event_id` |

Trace of One Measure: `deaths_direct`

| Stage | Object and field | Rule | Observed |
|:------|:-----------------|:-----|---------:|
| Source | `bigquery-public-data.noaa_historic_severe_storms.storms_*.deaths_direct` | None | — |
| Raw | `storm_risk_raw.raw_storm_events.deaths_direct` | Copied unchanged | 11,305 |
| Curated | `storm_risk_curated.fact_storm_event.deaths_direct` | Selection rule: `ROW_NUMBER() OVER (PARTITION BY event_id ...)`, keep `rn = 1` | 7,293 |
| Serving (**planned, P3**) | `srv_state_hazard_shares` | Sum by `state_key` and `event_group`, divide by the state total, rank within state | Not yet built |

The Raw total counts a multi-location event's deaths once per location row. The Curated total equals the sum taken once per event. The selection rule removes the inflation of deaths without losing any. The planned Serving table will use the Curated value to rank each state's hazard groups by share of direct deaths.


#### 3. Run and interpret two acceptance checks

#### 4. Make the run reproducible and record the next step
