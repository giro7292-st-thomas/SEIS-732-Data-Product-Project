#### 1. Establish the input and run ingestion

Audience, primary analytical question, and changes from P1: This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years? Changes to P1 - Raw changed from a view to a table, so the input is a fixed copy that later steps will compare against.

Source Data:

Source objects project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Raw input and preservation:

The raw table that I am creating keep every source column and row preserved. As a result, this includes repeated event quantities on each location row; raw does not deduplicate or filter any data. Two fields are added, `source_year` and `loaded_at` which help as multiple years worth of data are combined into a single table and adds metadata as to when the Source->Raw ingestion was ran.

Last Run: 2026-11-09 00:44:53.245406 UTC

Build info: Project `peppy-castle-507918-u6`, location `US`

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

The Raw total counts a multi-location event's deaths once per location row. The Curated total equals the sum taken once per event. The selection rule removes the inflation of deaths without losing any. The planned Serving table will use the Curated value to rank each state's hazard groups by share of direct deaths. Ranking hazards within a state will only be correct if each event is counted only once and keeps its state, date, and hazard grouping.

#### 3. Run and interpret two acceptance checks

| Risk and affected result | Check code | Expected result and why | Observed result | Interpretation or action |
|:-------------------------|:-----------|:------------------------|:----------------|:-------------------------|
| **Curated grain and relationships.** An event is lost or duplicated when the fact is built and joined, or has no hazard group. This would inflate or drop deaths, injuries, and damage in a states hazard ranking. | `sql/04_acceptance.sql`, Check 1 | 0 in every column. No repeated `event_id`, every Raw event is present in the fact, every date_key, state_key, and hazard_key matches its dimension, and every hazard has an event_group. A violation indicates a row is miscounted or excluded from the state and hazard totals. | repeated: 0, missing: 0, date: 0, state: 0, hazard: 0 | Every event_id still identifies exactly one Curated row. Every event in Raw was ingested into the fact with a matching date, state and hazard group, so no event is lost or double-counted. |
| **Row meaning for the audience result.** A Curated row may not represent its event's true impact for its state. This would make the planned state totals and hazard shares wrong. Revised from P1 Risk 2: shares-sum-to-100% moves to P3 once Serving exists. | `sql/04_acceptance.sql`, Check 2 | `mismatched_states = 0`. Each state's fact total should equal an independent Raw total that counts each `event_id` once. | states: 69, mismatched: 0 | All 69 FIPS codes Curated totals for each measure match an independent once-per-event total from Raw. Each fact row carries its own measures for the right state, and state totals built from the fact can be trusted in Serving. |

#### 4. Make the run reproducible and record the next step

**Prerequisites (must exist before step 1):**
- A Google Cloud project with BigQuery enabled and billing (`peppy-castle-507918-u6`), processing location `US`
- Read access to `bigquery-public-data.noaa_historic_severe_storms.storms_2016` through `storms_2025`
- Read access to `bigquery-public-data.geo_us_boundaries.states` (used by `dim_state`) for FIPS

1. **Create the Raw dataset.** [`02_ingest.sql`](https://github.com/giro7292-st-thomas/SEIS-732-Data-Product-Project/blob/main/sql/02_ingest.sql), step 1
   - Creates `storm_risk_raw` if it is not already there. No change if it already exists.
2. **Record the source version.** `02_ingest.sql`, step 2
   - Read-only. Run before the load.
   - **Save:** `last_modified` and the row count for each source table.
3. **Check schema consistency.** `02_ingest.sql`, step 3
   - Read-only. Expect 0 rows.
4. **Load Raw.** `02_ingest.sql`, step 4
   - Requires steps 1–3.
   - **Replaces** `raw_storm_events` and resets `loaded_at`.
   - **Save before a reload:** the previous `loaded_at` and row count. A reload overwrites the copy every later result was built from.
5. **Verify Raw.** `02_ingest.sql`, step 5
   - Read-only. Expect 881,554 rows, events from 2016-01-01 to 2025-12-31.
   - **Save:** row count, first and last event, and `loaded_at`.
6. **Create the Curated dataset and `dim_date`.** [`03_curate.sql`](https://github.com/giro7292-st-thomas/SEIS-732-Data-Product-Project/blob/main/sql/03_curate.sql), "Create dim_date"
   - Creates `storm_risk_curated` if missing; **replaces** `dim_date`.
7. **Build and verify `dim_state`.** `03_curate.sql`, "Create dim_state" steps 1–3
   - Requires step 4. **Replaces** `dim_state`.
   - **Save:** the verification counts and the list of `OTHER` codes.
8. **Build `hazard_map`.** `03_curate.sql`, "Create hazard_map"
   - Requires step 4.
   - **Replaces** `hazard_map`; `map_key` values are renumbered and any history rows are lost.
   - **Save:** any manually added history rows (none in this submittal).
9. **Build `fact_storm_event`.** `03_curate.sql`, "Create fact_storm_event"
   - Requires steps 4, 6, 7 and 8. **Replaces** `fact_storm_event` and resets `load_date`.
10. **Validate Curated row counts.** `03_curate.sql`, "Validation" V1
    - Read-only. Expect `fact_rows` = `distinct_raw_events` = 653,920.
    - **Save:** all four counts.
11. **Run the acceptance checks.** [`04_acceptance.sql`](https://github.com/giro7292-st-thomas/SEIS-732-Data-Product-Project/blob/main/sql/04_acceptance.sql), Checks 1 and 2
    - Requires step 9. Read-only.
    - **Save:** both results (Section 3 table).

**Notes:**
- `fact_storm_event` takes `hazard_key` from `hazard_map`. If `hazard_map` is rebuilt, rerun step 9 and then steps 10–11, or the fact will point to renumbered keys.
- Every build step uses `CREATE OR REPLACE`, and nothing appends, so running steps 4–11 again rebuilds the same objects from scratch.

Limitation and next step: the `hazard_map` has the Type 2 fields (`valid_from`, `valid_to`, `is_current`) configured, but its created with `CREATE OR REPLACE` and numbers `map_key` with `ROW_NUMBER()`. Each label will therefore has only one version, and a rebuild would erase any closed versions and could renumber the keys the fact refers to. The history design is in place but not yet exercised. The next concrete step is to replace the full rebuild method in place with a versioned change and demonstrate versioning on one real label. My plan is to move storm surge/tide from Coastal Flood to Tropical Cyclone.

#### AI Disclaimer
AI was used to write the SQL for ingestion, curation, and acceptance; since the dataset is manageable in excel, I was able to review the anticipated selection rule and row counts in a different environment in addition to BigQuery. Further, AI assisted with the SQL creation for the checks by converting the description of what I wanted to check into code; this was first validated on a small scale (examining one state/FIPS code) before applying to the entire dataset. External sources were also referenced when researching FIPS codes along with gaining an understanding of how SQL mapping works. AI was also used for formatting tables and general text markup.
