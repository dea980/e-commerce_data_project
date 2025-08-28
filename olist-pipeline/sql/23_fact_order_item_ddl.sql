CREATE SCHEMA IF NOT EXISTS fact;

CREATE TABLE IF NOT EXISTS fact.order_item (
    order_id text NOT NULL,
    order_item_id int NOT NULL,
    product_id text NOT NULL,
    seller_id  text NOT NULL,
    price numeric(18,2),
    freight_value numeric(18,2),
    order_purchase_ts timestamptz,
    delivered_customer_ts timestamptz,
    estimated_delivery_ts timestamptz,
    review_score int,
    payment_value numeric(18,2),
    payment_type text,
    PRIMARY KEY(order_id, order_item_id)
);
