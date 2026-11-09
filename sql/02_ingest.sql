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
