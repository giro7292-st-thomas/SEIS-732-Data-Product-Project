-- Check 1: Total source rows
SELECT
  'Source rows' AS check_name,
  881554 AS expected,
  COUNT(*) AS observed
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Check 2: Source rows missing event_id
SELECT
  'Source rows missing event_id' AS check_name,
  0 AS expected,
  COUNTIF(event_id IS NULL) AS observed
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Check 3: Source rows missing location_index
-- Returned an unexpected result. Check 3a was added to review the missing location_index rows
SELECT
  'Source rows missing location_index' AS check_name,
  0 AS expected,
  COUNTIF(location_index IS NULL) AS observed
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Check 3a: Events with a missing location_index that also have other rows
SELECT
  'Events mixing missing and present location_index' AS check_name,
  0 AS expected,
  COUNT(*) AS observed
FROM (
  SELECT event_id
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025'
  GROUP BY event_id
  HAVING COUNTIF(location_index IS NULL) > 0 AND COUNT(*) > 1
);

-- Check 4: Source rows missing state_fips_code
SELECT
  'Source rows missing state_fips_code' AS check_name,
  0 AS expected,
  COUNTIF(state_fips_code IS NULL) AS observed
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Check 5: Source rows missing event_type
SELECT
  'Source rows missing event_type' AS check_name,
  0 AS expected,
  COUNTIF(event_type IS NULL) AS observed
FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025';

-- Check 6: Repeated (event_id, location_index) groups in source
SELECT
  'Repeated (event_id, location_index) groups' AS check_name,
  0 AS expected,
  COUNT(*) AS observed
FROM (
  SELECT event_id, location_index
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025'
  GROUP BY event_id, location_index
  HAVING COUNT(*) > 1
);

-- Check 7: Repeated event_id groups in source
SELECT
  'Repeated event_id groups in source' AS check_name,
  '> 0' AS expected,
  COUNT(*) AS observed
FROM (
  SELECT event_id
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025'
  GROUP BY event_id
  HAVING COUNT(*) > 1
);

-- Check 8: Fact rows match distinct source events
-- Confirms the fact grain: one row per event_id. Both numbers should equal 653,920.
WITH src AS (
  SELECT *
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025'
),
fact AS (
  SELECT * EXCEPT(rn)
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY location_index) AS rn
    FROM src
  )
  WHERE rn = 1
)
SELECT
  (SELECT COUNT(DISTINCT event_id) FROM src) AS distinct_source_events,
  (SELECT COUNT(*) FROM fact) AS fact_rows;
