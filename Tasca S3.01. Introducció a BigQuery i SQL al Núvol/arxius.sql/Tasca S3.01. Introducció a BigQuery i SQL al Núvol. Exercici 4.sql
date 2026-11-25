CREATE OR REPLACE TABLE
  `sprint-3-analytics-maksim`.sprint3_bronze.transactions_raw_native AS
SELECT
  *
FROM
  `sprint-3-analytics-maksim`.sprint3_bronze.transactions_raw;

SELECT id
FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw;

SELECT id
FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native LIMIT 10;

SELECT id FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw LIMIT 10;