-- Check 1: Curated grain and relationships (expect 0 in every column)
SELECT
  COUNT(*) - COUNT(DISTINCT f.event_id)                          AS repeated_event_ids,
  (SELECT COUNT(DISTINCT event_id)
     FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`)
    - COUNT(DISTINCT f.event_id)                                 AS raw_events_missing,
  COUNTIF(d.date_key IS NULL)                                    AS unmatched_date,
  COUNTIF(s.state_key IS NULL)                                   AS unmatched_state,
  COUNTIF(h.event_group IS NULL)                                 AS ungrouped_hazard
FROM `peppy-castle-507918-u6.storm_risk_curated.fact_storm_event` f
LEFT JOIN `peppy-castle-507918-u6.storm_risk_curated.dim_date`   d ON f.date_key   = d.date_key
LEFT JOIN `peppy-castle-507918-u6.storm_risk_curated.dim_state`  s ON f.state_key  = s.state_key
LEFT JOIN `peppy-castle-507918-u6.storm_risk_curated.hazard_map` h ON f.hazard_key = h.map_key;

-- Check 2: State totals match Raw counted once per event (expect 0 mismatched states)
WITH raw_state AS (
  SELECT state_key,
    SUM(deaths_direct) AS deaths_direct,     SUM(deaths_indirect) AS deaths_indirect,
    SUM(injuries_direct) AS injuries_direct, SUM(injuries_indirect) AS injuries_indirect,
    SUM(damage_property) AS damage_property, SUM(damage_crops) AS damage_crops
  FROM (
    SELECT event_id,
      LPAD(CAST(ANY_VALUE(state_fips_code) AS STRING), 2, '0') AS state_key,
      ANY_VALUE(deaths_direct) AS deaths_direct,     ANY_VALUE(deaths_indirect) AS deaths_indirect,
      ANY_VALUE(injuries_direct) AS injuries_direct, ANY_VALUE(injuries_indirect) AS injuries_indirect,
      ANY_VALUE(damage_property) AS damage_property, ANY_VALUE(damage_crops) AS damage_crops
    FROM `peppy-castle-507918-u6.storm_risk_raw.raw_storm_events`
    GROUP BY event_id
  )
  GROUP BY state_key
),
fact_state AS (
  SELECT state_key,
    SUM(deaths_direct) AS deaths_direct,     SUM(deaths_indirect) AS deaths_indirect,
    SUM(injuries_direct) AS injuries_direct, SUM(injuries_indirect) AS injuries_indirect,
    SUM(damage_property) AS damage_property, SUM(damage_crops) AS damage_crops
  FROM `peppy-castle-507918-u6.storm_risk_curated.fact_storm_event`
  GROUP BY state_key
)
SELECT
  (SELECT COUNT(*) FROM fact_state)                                                AS states_compared,
  (SELECT COUNT(*) FROM (SELECT * FROM raw_state EXCEPT DISTINCT SELECT * FROM fact_state))
  + (SELECT COUNT(*) FROM (SELECT * FROM fact_state EXCEPT DISTINCT SELECT * FROM raw_state)) AS mismatched_states;

