CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.products_clean` AS
SELECT
  CAST(id AS INT64) AS product_id,
  TRIM(product_name) AS name,
  SAFE_CAST(REGEXP_REPLACE(CAST(price AS STRING), r'[^0-9.-]', '') AS FLOAT64) AS price,
  colour,
  weight,
  CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  category,
  brand,
  SAFE_CAST(REGEXP_REPLACE(CAST(cost AS STRING), r'[^0-9.-]', '') AS FLOAT64) AS cost,
  CAST(launch_date AS DATE) AS launch_date
FROM `sprint-3-analytics-maksim.sprint3_bronze.products_raw`;

SELECT *
FROM `sprint-3-analytics-maksim.sprint3_silver.products_clean`
LIMIT 3;