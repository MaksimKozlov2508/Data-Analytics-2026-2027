CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.transactions_clean` AS
SELECT
  TRIM(id) AS transaction_id,
  card_id,
  business_id,
  SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
  IFNULL(CAST(amount AS FLOAT64), 0) AS amount,
  SAFE_CAST(declined AS INT64) AS declined,
  ARRAY(
    SELECT SAFE_CAST(TRIM(pid) AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS pid
    WHERE TRIM(pid) != ''
  ) AS product_ids,
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
  FROM `sprint-3-analytics-maksim.sprint3_bronze.transactions_raw`;

  SELECT *
  FROM `sprint-3-analytics-maksim.sprint3_silver.transactions_clean`
  LIMIT 3;
