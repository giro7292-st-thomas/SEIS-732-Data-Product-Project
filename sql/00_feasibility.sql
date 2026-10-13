-- Record the authorized objects and inspect their definitions.
SELECT column_name, data_type, is_nullable
FROM `bigquery-public-data.noaa_historic_severe_storms.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'storms_2025'
ORDER BY ordinal_position;

-- Establish basic scale without exporting row-level data.
SELECT COUNT(*) AS row_count
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Test the time coverage and candidate identifier relevant to the idea.
SELECT
    MIN(event_begin_time) AS earliest_date,
    MAX(event_begin_time) AS latest_date,
    COUNTIF(event_id IS NULL) AS null_candidate_ids,
    COUNT(DISTINCT event_id) AS distinct_candidate_ids
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';
