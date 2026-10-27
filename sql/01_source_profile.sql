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

-- Check 8: Events whose measures or key attributes vary across location rows
-- Tests the selection rule: if 0, keeping one row per event_id loses no information.
SELECT
  'Events with varying values across location rows' AS check_name,
  0 AS expected,
  COUNT(*) AS observed
FROM (
  SELECT event_id
  FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
  WHERE _TABLE_SUFFIX BETWEEN '2016' AND '2025'
  GROUP BY event_id
  HAVING COUNT(DISTINCT deaths_direct) > 1
      OR COUNT(DISTINCT deaths_indirect) > 1
      OR COUNT(DISTINCT injuries_direct) > 1
      OR COUNT(DISTINCT injuries_indirect) > 1
      OR COUNT(DISTINCT damage_property) > 1
      OR COUNT(DISTINCT damage_crops) > 1
      OR COUNT(DISTINCT event_type) > 1
      OR COUNT(DISTINCT state_fips_code) > 1
      OR COUNT(DISTINCT cz_fips_code) > 1
      OR COUNT(DISTINCT event_begin_time) > 1
);
