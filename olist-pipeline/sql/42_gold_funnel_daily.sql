CREATE TABLE IF NOT EXISTS gold.funnel_daily(
    ds_utc date PRIMARY KEY,
    placed int,
    approved int,
    delivered int
);

INSERT INTO gold.funnel_daily(ds_utc, placed, approved, delivered)
SELECT
    {{ ds }}::date,
    COUNT(*) FILTER (WHERE o.order_purchase_ts::date = {{ ds }}::date),
    COUNT(*) FILTER (WHERE o.order_approved_ts::date = {{ ds }}::date),
    COUNT(*) FILTER (WHERE o.delivered_customer_ts::date = {{ ds }}::date)
FROM ods.orders o
ON CONFLICT (ds_utc) DO UPDATE SET
    placed=EXCLUDED.placed, approved=EXCLUDED.approved, delivered=EXCLUDED.delivered;
