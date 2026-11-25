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