CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_gold.product_sales_ranking` AS
WITH sold_products AS (
  SELECT
    pid AS product_id
  FROM `sprint-3-analytics-maksim.sprint3_silver.transactions_clean` t
  CROSS JOIN UNNEST(t.product_ids) AS pid
  WHERE t.declined = 0
)
SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour AS color,
  COUNT(s.product_id) AS total_sold
FROM `sprint-3-analytics-maksim.sprint3_silver.products_clean` p
LEFT JOIN sold_products s
  ON p.product_id = s.product_id
GROUP BY
  p.product_id,
  p.name,
  p.price,
  p.colour
ORDER BY
  total_sold DESC,
  p.product_id ASC;