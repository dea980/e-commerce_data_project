CREATE SCHEMA IF NOT EXISTS ods;

-- customers
CREATE TABLE IF NOT EXISTS ods.customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

-- orders
CREATE TABLE IF NOT EXISTS ods.orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_ts TIMESTAMPTZ,
    order_approved_ts TIMESTAMPTZ,
    delivered_carrier_ts TIMESTAMPTZ,
    delivered_customer_ts TIMESTAMPTZ,
    estimated_delivery_ts TIMESTAMPTZ,
    CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES ods.customers(customer_id)
);

-- order_items
CREATE TABLE IF NOT EXISTS ods.order_items (
    order_id TEXT NOT NULL,
    order_item_id INT NOT NULL,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_ts TIMESTAMPTZ,
    price NUMERIC(18,2),
    freight_value NUMERIC(18,2),
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_order
    FOREIGN KEY (order_id) REFERENCES ods.orders(order_id)
);

-- payments
CREATE TABLE IF NOT EXISTS ods.payments (
    order_id TEXT NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC(18,2) NOT NULL CHECK (payment_value >= 0),
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_pay_order
    FOREIGN KEY (order_id) REFERENCES ods.orders(order_id)
);

-- reviews
CREATE TABLE IF NOT EXISTS ods.reviews (
    review_id TEXT PRIMARY KEY,
    order_id TEXT UNIQUE,
    review_score INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_ts TIMESTAMPTZ,
    review_answer_ts TIMESTAMPTZ,
    CONSTRAINT fk_rev_order
    FOREIGN KEY (order_id) REFERENCES ods.orders(order_id)
);
