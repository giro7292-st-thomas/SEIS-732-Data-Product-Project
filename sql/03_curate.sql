-- Create dim_date
CREATE SCHEMA IF NOT EXISTS `peppy-castle-507918-u6.storm_risk_curated`
OPTIONS (location = 'US');

CREATE OR REPLACE TABLE `peppy-castle-507918-u6.storm_risk_curated.dim_date` AS
SELECT
  CAST(FORMAT_DATE('%Y%m%d', d) AS INT64) AS date_key,   -- e.g. 20160101
  d                                       AS full_date,
  EXTRACT(YEAR FROM d)                    AS year,
  EXTRACT(QUARTER FROM d)                 AS quarter,
  EXTRACT(MONTH FROM d)                   AS month
FROM UNNEST(GENERATE_DATE_ARRAY('2016-01-01', '2025-12-31')) AS d;

-- Create dim_state (FIPS code for reference: https://transition.fcc.gov/oet/info/maps/census/fips/fips.txt)
-- 1. Review FIPS codes used in `storm_risk_curated`
SELECT
  state_fips_code,
  LENGTH(CAST(state_fips_code AS STRING)) AS fips_length,
  MIN(state)                              AS raw_state_label,
  COUNT(*)                                AS raw_rows
FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
GROUP BY 1, 2
ORDER BY 1;

-- 2. Table creation
CREATE OR REPLACE TABLE `peppy-castle-507918-u6.storm_risk_curated.dim_state` AS
WITH census AS (
  SELECT
    state_fips_code AS state_key,
    state_name,
    state           AS state_abbr,
    CASE
      WHEN state_fips_code = '11' THEN 'DC'
      WHEN state_fips_code IN ('60','66','69','72','78') THEN 'TERRITORY'
      ELSE 'STATE'
    END AS geo_type
  FROM `bigquery-public-data.geo_us_boundaries.states`
),
observed AS (
  SELECT
    LPAD(CAST(state_fips_code AS STRING), 2, '0') AS state_key,
    MIN(state)                                    AS raw_state_label
  FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
  GROUP BY 1
)
SELECT * FROM census
UNION ALL
SELECT o.state_key, o.raw_state_label, CAST(NULL AS STRING), 'OTHER'
FROM observed o
LEFT JOIN census c USING (state_key)
WHERE c.state_key IS NULL;

-- 3. Verification
SELECT
  COUNT(*)                         AS row_count,
  COUNT(DISTINCT state_key)        AS distinct_keys,   -- must equal row_count
  COUNTIF(geo_type = 'STATE')      AS states,          -- expect 50
  COUNTIF(geo_type = 'DC')         AS dc,              -- expect 1
  COUNTIF(geo_type = 'TERRITORY')  AS territories,
  COUNTIF(geo_type = 'OTHER')      AS other_codes
FROM `peppy-castle-507918-u6.storm_risk_curated.dim_state`;

-- What the OTHER rows are and how much of Raw they cover
SELECT s.state_key, s.state_name, COUNT(*) AS raw_rows
FROM `peppy-castle-507918-u6.storm_risk_curated.dim_state` s
JOIN `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events` r
  ON s.state_key = LPAD(CAST(r.state_fips_code AS STRING), 2, '0')
WHERE s.geo_type = 'OTHER'
GROUP BY 1, 2
ORDER BY raw_rows DESC;

-- Create hazard_map (grouping hazards by similarities) with history fields.
CREATE OR REPLACE TABLE `peppy-castle-507918-u6.storm_risk_curated.hazard_map` AS
WITH labels AS (
  SELECT DISTINCT event_type
  FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
),
mapping AS (
  SELECT * FROM UNNEST([
    STRUCT('tornado' AS event_type, 'Tornado' AS event_group),
    ('funnel cloud', 'Tornado'),
    ('waterspout', 'Tornado'),

    ('thunderstorm wind', 'Thunderstorm Wind'),
    ('marine thunderstorm wind', 'Thunderstorm Wind'),

    ('hail', 'Hail'),
    ('marine hail', 'Hail'),

    ('lightning', 'Lightning'),
    ('marine lightning', 'Lightning'),

    ('high wind', 'High Wind'),
    ('strong wind', 'High Wind'),
    ('marine high wind', 'High Wind'),
    ('marine strong wind', 'High Wind'),

    ('flash flood', 'Flood'),
    ('flood', 'Flood'),
    ('heavy rain', 'Flood'),

    ('coastal flood', 'Coastal Flood'),
    ('lakeshore flood', 'Coastal Flood'),
    ('storm surge/tide', 'Coastal Flood'),

    ('high surf', 'Surf and Tides'),
    ('rip current', 'Surf and Tides'),
    ('sneakerwave', 'Surf and Tides'),
    ('seiche', 'Surf and Tides'),
    ('tsunami', 'Surf and Tides'),
    ('astronomical low tide', 'Surf and Tides'),

    ('tropical storm', 'Tropical Cyclone'),
    ('tropical depression', 'Tropical Cyclone'),
    ('hurricane (typhoon)', 'Tropical Cyclone'),
    ('marine tropical storm', 'Tropical Cyclone'),
    ('marine tropical depression', 'Tropical Cyclone'),
    ('marine hurricane/typhoon', 'Tropical Cyclone'),

    ('heavy snow', 'Snow'),
    ('lake-effect snow', 'Snow'),
    ('blizzard', 'Snow'),

    ('winter storm', 'Winter Weather'),
    ('winter weather', 'Winter Weather'),
    ('ice storm', 'Winter Weather'),
    ('sleet', 'Winter Weather'),
    ('freezing fog', 'Winter Weather'),

    ('cold/wind chill', 'Extreme Cold'),
    ('extreme cold/wind chill', 'Extreme Cold'),
    ('frost/freeze', 'Extreme Cold'),

    ('heat', 'Heat'),
    ('excessive heat', 'Heat'),

    ('drought', 'Drought'),
    ('wildfire', 'Wildfire'),

    ('dense fog', 'Fog, Dust and Smoke'),
    ('marine dense fog', 'Fog, Dust and Smoke'),
    ('dense smoke', 'Fog, Dust and Smoke'),
    ('dust storm', 'Fog, Dust and Smoke'),
    ('dust devil', 'Fog, Dust and Smoke'),

    ('debris flow', 'Landslide and Geologic'),
    ('avalanche', 'Landslide and Geologic'),
    ('volcanic ashfall', 'Landslide and Geologic')
  ])
)
SELECT
  ROW_NUMBER() OVER (ORDER BY l.event_type) AS map_key,
  l.event_type,
  m.event_group,
  DATE '2016-01-01'  AS valid_from,
  CAST(NULL AS DATE) AS valid_to,
  TRUE               AS is_current
FROM labels l
LEFT JOIN mapping m USING (event_type);

-- Create `fact_storm_event`. Run after creating all other tables.
CREATE OR REPLACE TABLE `peppy-castle-507918-u6.storm_risk_curated.fact_storm_event` AS
WITH one_per_event AS (
  SELECT * EXCEPT (rn)
  FROM (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY event_id
        ORDER BY SAFE_CAST(location_index AS INT64), source_year
      ) AS rn
    FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
  )
  WHERE rn = 1
)
SELECT
  e.event_id,
  e.episode_id,
  CAST(FORMAT_DATE('%Y%m%d', DATE(e.event_begin_time)) AS INT64) AS date_key,
  LPAD(CAST(e.state_fips_code AS STRING), 2, '0')                AS state_key,
  h.map_key                                                      AS hazard_key,
  e.event_type,
  e.cz_type,
  e.cz_fips_code,
  e.deaths_direct,
  e.deaths_indirect,
  e.injuries_direct,
  e.injuries_indirect,
  e.damage_property,
  e.damage_crops,
  CURRENT_DATE() AS load_date
FROM one_per_event e
LEFT JOIN `peppy-castle-507918-u6.storm_risk_curated.hazard_map` h
  ON e.event_type = h.event_type AND h.is_current;
