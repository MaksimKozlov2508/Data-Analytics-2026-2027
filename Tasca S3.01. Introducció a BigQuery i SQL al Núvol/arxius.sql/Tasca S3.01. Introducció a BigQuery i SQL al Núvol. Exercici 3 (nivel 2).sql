CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  PARSE_DATE('%b %d, %Y', birth_date) AS birth_date,
  country,
  city,
  postal_code,
  address,
  'America' AS origin
FROM `sprint-3-analytics-maksim.sprint3_bronze.american_users_raw`

UNION ALL

SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  PARSE_DATE('%b %d, %Y', birth_date) AS birth_date,
  country,
  city,
  postal_code,
  address,
  'Europe' AS origin
FROM `sprint-3-analytics-maksim.sprint3_bronze.european_users_raw`;

SELECT *
FROM `sprint-3-analytics-maksim.sprint3_silver.users_combined`
LIMIT 3;