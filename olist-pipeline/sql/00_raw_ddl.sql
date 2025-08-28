CREATE SCHEMA IF NOT EXISTS raw;

-- olist.orders
CREATE TABLE IF NOT EXISTS raw.orders_raw(
    order_id TEXT, customer_id TEXT, order_status TEXT,
    order_purchase_timestamp TEXT, order_approved_at TEXT,
    order_delivered_carrier_date TEXT, order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);
-- olist.order_items
CREATE TABLE IF NOT EXISTS raw.order_items_raw(
    order_id TEXT, order_item_id TEXT, product_id TEXT, seller_id TEXT,
    shipping_limit_date TEXT, price TEXT, freight_value TEXT
);
-- olist.customers
CREATE TABLE IF NOT EXISTS raw.customers_raw(
    customer_id TEXT, customer_unique_id TEXT, customer_zip_code_prefix TEXT,
    customer_city TEXT, customer_state TEXT
);
-- olist.payments
CREATE TABLE IF NOT EXISTS raw.payments_raw(
    order_id TEXT, payment_sequential TEXT, payment_type TEXT,
    payment_installments TEXT, payment_value TEXT
);
-- olist.reviews
CREATE TABLE IF NOT EXISTS raw.reviews_raw(
    review_id TEXT, order_id TEXT, review_score TEXT,
    review_comment_title TEXT, review_comment_message TEXT,
    review_creation_date TEXT, review_answer_timestamp TEXT
);
-- olist.products
CREATE TABLE IF NOT EXISTS raw.products_raw(
    product_id TEXT, product_category_name TEXT, product_name_lenght TEXT,
    product_description_lenght TEXT, product_photos_qty TEXT, product_weight_g TEXT,
    product_length_cm TEXT, product_height_cm TEXT, product_width_cm TEXT
);
-- olist.sellers
CREATE TABLE IF NOT EXISTS raw.sellers_raw(
    seller_id TEXT, seller_zip_code_prefix TEXT, seller_city TEXT, seller_state TEXT
);
-- olist.geolocation
CREATE TABLE IF NOT EXISTS raw.geolocation_raw(
    geolocation_zip_code_prefix TEXT, geolocation_lat TEXT, geolocation_lng TEXT,
    geolocation_city TEXT, geolocation_state TEXT
);
-- olist.product_category_translation
CREATE TABLE IF NOT EXISTS raw.product_category_translation_raw(
    product_category_name TEXT, product_category_name_english TEXT
);
