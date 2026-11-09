#### 1. Establish the input and run ingestion

Audience, primary analytical question, and changes from P1: This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years? No changes to P1 source or grain.

Source Data:

Source objects project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Raw input and preservation:

The raw table that I am creating keep every source column and row preserved. As a result, this includes repeated event quantities on each location row; raw does not deduplicate or filter any data. Two fields are added, `source_year` and `loaded_at` which help as multiple years worth of data are combined into a single table and adds metadata as to when the Source->Raw was ran.

```
-- 1. Dataset (location must match the public dataset)
CREATE SCHEMA IF NOT EXISTS `peppy-castle-507918-u6.storm_risk_raw`
OPTIONS (location = 'US');

-- 2. Pre-load: record the source version (run BEFORE the load)
SELECT
  table_id,
  TIMESTAMP_MILLIS(creation_time)      AS source_created,
  TIMESTAMP_MILLIS(last_modified_time) AS source_last_modified,
  row_count                            AS source_rows,
  size_bytes
FROM `bigquery-public-data.noaa_historic_severe_storms.__TABLES__`
WHERE REGEXP_CONTAINS(table_id, r'^storms_(201[6-9]|202[0-5])$')
ORDER BY table_id;

-- 3. Pre-load: schema consistency across the 10 tables (expect 0 rows)
SELECT column_name, data_type, COUNT(DISTINCT table_name) AS tables_with_column
FROM `bigquery-public-data.noaa_historic_severe_storms.INFORMATION_SCHEMA.COLUMNS`
WHERE REGEXP_CONTAINS(table_name, r'^storms_(201[6-9]|202[0-5])$')
GROUP BY column_name, data_type
HAVING tables_with_column < 10;

-- 4. Load Raw (point-in-time copy)
CREATE OR REPLACE TABLE `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
OPTIONS (description = 'Unmodified copy of NOAA storms_2016-2025 (one row per event location) plus source_year and loaded_at lineage columns.')
AS
SELECT
  *,
  _TABLE_SUFFIX       AS source_year,
  CURRENT_TIMESTAMP() AS loaded_at
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';
```
