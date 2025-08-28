CREATE TABLE IF NOT EXISTS gold.payment_mix_daily(
    ds_utc date,
    payment_type text,
    orders int,
    amount numeric(18,2),
    PRIMARY KEY(ds_utc, payment_type)
);

INSERT INTO gold.payment_mix_daily(ds_utc, payment_type, orders, amount)
SELECT
    {{ ds }}::date, p.payment_type,
    COUNT(DISTINCT p.order_id),
    SUM(p.payment_value)
FROM ods.payments p
JOIN ods.orders o ON o.order_id = p.order_id
WHERE o.order_purchase_ts::date = {{ ds }}::date
GROUP BY 1,2
ON CONFLICT (ds_utc, payment_type) DO UPDATE SET
    orders=EXCLUDED.orders, amount=EXCLUDED.amount;

CREATE TABLE IF NOT EXISTS gold.payment_approval_daily(
    ds_utc date PRIMARY KEY,
    approval_rate float
);
INSERT INTO gold.payment_approval_daily(ds_utc, approval_rate)
SELECT
    {{ ds }}::date,
    COUNT(*) FILTER (WHERE order_approved_ts IS NOT NULL AND order_purchase_ts::date={{ ds }}::date)::float
    / NULLIF(COUNT(*) FILTER (WHERE order_purchase_ts::date={{ ds }}::date),0)
FROM ods.orders
ON CONFLICT (ds_utc) DO UPDATE SET approval_rate=EXCLUDED.approval_rate;
