SELECT *
FROM `sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native`
LIMIT 3;

SELECT column_name, data_type
FROM `sprint-3-analytics-maksim.sprint3_bronze.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name='transactions_raw_native';

SELECT
  DATE(CAST(timestamp AS TIMESTAMP)) AS fecha,
  ROUND(SUM(amount), 2) AS ingresos_totales
FROM `sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM CAST(timestamp AS TIMESTAMP)) = 2021
  AND CAST(declined AS INT64) = 0
GROUP BY fecha
ORDER BY ingresos_totales DESC
LIMIT 5;