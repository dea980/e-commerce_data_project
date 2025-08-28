CREATE TABLE IF NOT EXISTS gold.delay_top_seller_daily(
    ds_utc date,
    seller_id text,
    delay_rate float,
    orders int,
    PRIMARY KEY(ds_utc, seller_id)
);

INSERT INTO gold.delay_top_seller_daily(ds_utc, seller_id, delay_rate, orders)
SELECT
    {{ ds }}::date,
    f.seller_id,
    AVG((f.delivered_customer_ts > f.estimated_delivery_ts)::int),
    COUNT(*)
FROM fact.order_item f
WHERE f.order_purchase_ts::date = {{ ds }}::date
GROUP BY 1,2
HAVING COUNT(*) >= 10
ON CONFLICT (ds_utc, seller_id) DO UPDATE SET
    delay_rate=EXCLUDED.delay_rate,
    orders=EXCLUDED.orders;
