CREATE TABLE IF NOT EXISTS gold.cohort_monthly_retention(
    ds_utc date,
    cohort_month text,
    active_month text,
    retention float,
    PRIMARY KEY(ds_utc, cohort_month, active_month)
);

WITH first_order AS (
    SELECT c.customer_unique_id, MIN(o.order_purchase_ts::date) AS first_dt
    FROM ods.orders o
    JOIN ods.customers c ON c.customer_id = o.customer_id
    GROUP BY 1
),
orders_by_cust AS (
    SELECT c.customer_unique_id, o.order_purchase_ts::date AS od
    FROM ods.orders o
    JOIN ods.customers c ON c.customer_id = o.customer_id
    )
INSERT INTO gold.cohort_monthly_retention(ds_utc, cohort_month, active_month, retention)
SELECT
    {{ ds }}::date,
    to_char(date_trunc('month', f.first_dt), 'YYYY-MM'),
    to_char(date_trunc('month', o.od), 'YYYY-MM'),
    COUNT(DISTINCT o.customer_unique_id)::float
    / NULLIF(COUNT(DISTINCT CASE WHEN date_trunc('month', f.first_dt)=date_trunc('month', f.first_dt) THEN f.customer_unique_id END),0)
FROM first_order f
JOIN orders_by_cust o USING(customer_unique_id)
GROUP BY 1,2,3
ON CONFLICT DO NOTHING;
