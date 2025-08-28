-- customers
INSERT INTO ods.customers AS c
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT DISTINCT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
FROM raw.customers_raw WHERE customer_id IS NOT NULL
ON CONFLICT (customer_id) DO UPDATE SET
    customer_unique_id = EXCLUDED.customer_unique_id,
    customer_zip_code_prefix = EXCLUDED.customer_zip_code_prefix,
    customer_city = EXCLUDED.customer_city,
    customer_state = EXCLUDED.customer_state;

-- orders
INSERT INTO ods.orders AS o
(order_id, customer_id, order_status, order_purchase_ts, order_approved_ts,
    delivered_carrier_ts, delivered_customer_ts, estimated_delivery_ts)
SELECT
    order_id, customer_id, order_status,
    NULLIF(order_purchase_timestamp,'')::timestamptz,
    NULLIF(order_approved_at,'')::timestamptz,
    NULLIF(order_delivered_carrier_date,'')::timestamptz,
    NULLIF(order_delivered_customer_date,'')::timestamptz,
    NULLIF(order_estimated_delivery_date,'')::timestamptz
FROM raw.orders_raw WHERE order_id IS NOT NULL
ON CONFLICT (order_id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    order_status = EXCLUDED.order_status,
    order_purchase_ts = EXCLUDED.order_purchase_ts,
    order_approved_ts = EXCLUDED.order_approved_ts,
    delivered_carrier_ts = EXCLUDED.delivered_carrier_ts,
    delivered_customer_ts = EXCLUDED.delivered_customer_ts,
    estimated_delivery_ts = EXCLUDED.estimated_delivery_ts;

-- order_items
INSERT INTO ods.order_items AS oi
(order_id, order_item_id, product_id, seller_id, shipping_limit_ts, price, freight_value)
SELECT
    order_id,
    NULLIF(order_item_id,'')::int,
    product_id, seller_id,
    NULLIF(shipping_limit_date,'')::timestamptz,
    NULLIF(price,'')::numeric(18,2),
    NULLIF(freight_value,'')::numeric(18,2)
FROM raw.order_items_raw
WHERE order_id IS NOT NULL AND order_item_id ~ '^[0-9]+$'
ON CONFLICT (order_id, order_item_id) DO UPDATE SET
    product_id = EXCLUDED.product_id,
    seller_id = EXCLUDED.seller_id,
    shipping_limit_ts = EXCLUDED.shipping_limit_ts,
    price = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value;

-- payments
INSERT INTO ods.payments AS p
(order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT
    order_id,
    NULLIF(payment_sequential,'')::int,
    payment_type,
    NULLIF(payment_installments,'')::int,
    NULLIF(payment_value,'')::numeric(18,2)
FROM raw.payments_raw
WHERE order_id IS NOT NULL AND payment_sequential ~ '^[0-9]+$'
ON CONFLICT (order_id, payment_sequential) DO UPDATE SET
    payment_type = EXCLUDED.payment_type,
    payment_installments = EXCLUDED.payment_installments,
    payment_value = EXCLUDED.payment_value;

-- reviews
INSERT INTO ods.reviews AS r
(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_ts, review_answer_ts)
SELECT
    review_id, order_id, NULLIF(review_score,'')::int,
    review_comment_title, review_comment_message,
    NULLIF(review_creation_date,'')::timestamptz,
    NULLIF(review_answer_timestamp,'')::timestamptz
FROM raw.reviews_raw
WHERE review_id IS NOT NULL
ON CONFLICT (review_id) DO UPDATE SET
    order_id = EXCLUDED.order_id,
    review_score = EXCLUDED.review_score,
    review_comment_title = EXCLUDED.review_comment_title,
    review_comment_message = EXCLUDED.review_comment_message,
    review_creation_ts = EXCLUDED.review_creation_ts,
    review_answer_ts = EXCLUDED.review_answer_ts;
