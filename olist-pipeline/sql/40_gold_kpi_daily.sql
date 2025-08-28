CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS gold.kpi_daily(
    ds_utc date PRIMARY KEY,
    orders int,
    gmv numeric(18,2),
    aov numeric(18,2),
    avg_delivery_days float,
    delay_rate float,
    avg_review float,
    negative_review_ratio float
);

INSERT INTO gold.kpi_daily AS g(
    ds_utc, orders, gmv, aov, avg_delivery_days, delay_rate, avg_review, negative_review_ratio
)
SELECT
    {{ ds }}::date AS ds_utc,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.price + f.freight_value) AS gmv,
    AVG(f.price + f.freight_value) AS aov,
    AVG(EXTRACT(EPOCH FROM (f.delivered_customer_ts - f.order_purchase_ts))/86400.0) AS avg_delivery_days,
    AVG((f.delivered_customer_ts > f.estimated_delivery_ts)::int) AS delay_rate,
    AVG(NULLIF(f.review_score,0)) AS avg_review,
    AVG((COALESCE(f.review_score,5) <= 2)::int) AS negative_review_ratio
FROM fact.order_item f
JOIN ods.orders o USING(order_id)
WHERE o.order_status = 'delivered'
    AND f.order_purchase_ts::date = {{ ds }}::date
ON CONFLICT (ds_utc) DO UPDATE SET
    orders=EXCLUDED.orders, gmv=EXCLUDED.gmv, aov=EXCLUDED.aov,
    avg_delivery_days=EXCLUDED.avg_delivery_days, delay_rate=EXCLUDED.delay_rate,
    avg_review=EXCLUDED.avg_review, negative_review_ratio=EXCLUDED.negative_review_ratio;
