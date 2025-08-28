INSERT INTO fact.order_item AS f (
    order_id, order_item_id, product_id, seller_id,
    price, freight_value,
    order_purchase_ts, delivered_customer_ts, estimated_delivery_ts,
    review_score, payment_value, payment_type
)
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    o.order_purchase_ts,
    o.delivered_customer_ts,
    o.estimated_delivery_ts,
    r.review_score,
    p.payment_value,
    p.payment_type
FROM ods.order_items oi
JOIN ods.orders   o ON o.order_id = oi.order_id
LEFT JOIN ods.reviews  r ON r.order_id = oi.order_id
LEFT JOIN LATERAL (
    SELECT payment_value, payment_type
    FROM ods.payments p
    WHERE p.order_id = oi.order_id
    ORDER BY payment_sequential DESC
    LIMIT 1
) p ON true
-- 증분 배치 시 활성화:
-- WHERE o.order_purchase_ts::date = {{ ds }}::date
ON CONFLICT (order_id, order_item_id) DO UPDATE SET
    product_id = EXCLUDED.product_id,
    seller_id  = EXCLUDED.seller_id,
    price      = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value,
    order_purchase_ts = EXCLUDED.order_purchase_ts,
    delivered_customer_ts = EXCLUDED.delivered_customer_ts,
    estimated_delivery_ts = EXCLUDED.estimated_delivery_ts,
    review_score = EXCLUDED.review_score,
    payment_value = EXCLUDED.payment_value,
    payment_type  = EXCLUDED.payment_type;
