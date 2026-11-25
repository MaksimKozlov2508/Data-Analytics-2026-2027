SELECT *
FROM `sprint-3-analytics-maksim.sprint3_bronze.companies_raw`
LIMIT 3;

SELECT c.company_name, c.country, DATE(CAST(t.timestamp AS TIMESTAMP)) AS fecha
FROM `sprint-3-analytics-maksim.sprint3_bronze.companies_raw` c
INNER JOIN `sprint-3-analytics-maksim.sprint3_bronze.transactions_raw` t
  ON c.company_id = t.business_id
WHERE DATE(CAST(t.timestamp AS TIMESTAMP)) IN (
  DATE('2015-04-29'),
  DATE('2018-07-20'),
  DATE('2024-03-13')
  )
  AND t.amount BETWEEN 100 AND 200
  AND CAST(t.declined AS INT64) = 0
ORDER BY fecha DESC;