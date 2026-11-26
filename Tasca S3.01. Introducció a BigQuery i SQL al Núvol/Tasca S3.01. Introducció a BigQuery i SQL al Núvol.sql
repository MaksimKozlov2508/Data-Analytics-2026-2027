-- Nivell 1: Entorn i Ingesta Híbrida (Code-First)

-- Exercici 1: Arquitectura de Dades (Lògica vs. Física)
CREATE SCHEMA `sprint-3-analytics-maksim.sprint3_silver`
OPTIONS (
  location='EU'
);

-- Exercici 2: Ingesta en Capa Bronze (Connexió DDL)
CREATE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';'
);

CREATE OR REPLACE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.tmp_check`
(raw_line STRING)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  field_delimiter = '\x01'
);

SELECT raw_line 
FROM `sprint-3-analytics-maksim.sprint3_bronze.tmp_check` 
LIMIT 2;

CREATE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

CREATE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  field_delimiter = ','
);

CREATE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  field_delimiter = ','
);

CREATE EXTERNAL TABLE `sprint-3-analytics-maksim.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  field_delimiter = ','
);

-- Exercici 4: Arquitectura i Rendiment. Materialització de Dades (Assistit per IA)
-- a
CREATE OR REPLACE TABLE
  `sprint-3-analytics-maksim`.sprint3_bronze.transactions_raw_native AS
SELECT
  *
FROM
  `sprint-3-analytics-maksim`.sprint3_bronze.transactions_raw;

-- b
SELECT id
FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw;

SELECT id
FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

-- c
SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native LIMIT 10;

SELECT id FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw_native;

SELECT * FROM sprint-3-analytics-maksim.sprint3_bronze.transactions_raw LIMIT 10;

-- Exercici 5: Adaptació de Sintaxi (Reporting)
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

-- Exercici 6: Consultes Complexes
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

-- Nivell 2: Neteja i Transformació (ELT)

--Exercici 1: Neteja de Productes (Data Quality)
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

-- Exercici 2: Creació de Transaccions Netes (Capa Silver)
CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.transactions_clean` AS
SELECT
  TRIM(id) AS transaction_id,
  card_id,
  business_id,
  SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
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

SELECT
  column_name,
  data_type,
  is_nullable
FROM `sprint-3-analytics-maksim.sprint3_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'transactions_clean';

-- Exercici 3: Unificació d'Usuaris (UNION)
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

-- Exercici 4: Materialització de Companyies i Targetes de Crèdit
CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint-3-analytics-maksim.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_silver.credit_cards_clean` AS
SELECT
  id AS card_id,
  * EXCEPT(id)
FROM `sprint-3-analytics-maksim.sprint3_bronze.credit_cards_raw`;

-- Nivell 3: Presentació de Dades i Creació de Vistes

-- Exercici 1: La Vista de Màrqueting (Lògica de Negoci)
CREATE OR REPLACE VIEW `sprint-3-analytics-maksim.sprint3_gold.v_marketing_kpis` AS
SELECT
  c.company_name,
  c.phone,
  c.country,
  ROUND(IFNULL(AVG(t.amount), 0), 2) AS avg_purchase,
  CASE
    WHEN IFNULL(AVG(t.amount), 0) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint-3-analytics-maksim.sprint3_silver.companies_clean` c
LEFT JOIN `sprint-3-analytics-maksim.sprint3_silver.transactions_clean` t
  ON c.company_id = t.business_id
  AND t.declined = 0
GROUP BY
  c.company_id,
  c.company_name,
  c.phone,
  c.country;

  SELECT *
FROM `sprint-3-analytics-maksim.sprint3_gold.v_marketing_kpis`
ORDER BY
  client_tier ASC,
  avg_purchase DESC;

-- Exercici 2: Rànquing de Productes (La Potència dels Arrays)
CREATE OR REPLACE TABLE `sprint-3-analytics-maksim.sprint3_gold.product_sales_ranking` AS
SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  COUNT(t.transaction_id) AS total_sold
FROM `sprint-3-analytics-maksim.sprint3_silver.products_clean` p
LEFT JOIN `sprint-3-analytics-maksim.sprint3_silver.transactions_clean` t
  ON p.product_id IN UNNEST(t.product_ids)
  AND t.declined = 0
GROUP BY
  p.product_id,
  p.name,
  p.price,
  p.colour
ORDER BY
  total_sold DESC,
  p.product_id ASC;

  -- Exercici 3: Exportació de Resultats
SELECT *
FROM `sprint-3-analytics-maksim.sprint3_gold.product_sales_ranking`
ORDER BY
  total_sold DESC,
  product_id ASC;