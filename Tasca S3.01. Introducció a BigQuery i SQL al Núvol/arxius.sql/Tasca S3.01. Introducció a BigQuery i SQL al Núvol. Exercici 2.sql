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