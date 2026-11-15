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

#### 3. Run and interpret two acceptance checks

#### 4. Make the run reproducible and record the next step
