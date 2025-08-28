-- 핵심 조회 키만 가볍게 인덱싱 (RAW라도 탐색/검증용)
CREATE INDEX IF NOT EXISTS ix_raw_orders_order_id          ON raw.orders_raw(order_id);
CREATE INDEX IF NOT EXISTS ix_raw_items_order_id           ON raw.order_items_raw(order_id);
CREATE INDEX IF NOT EXISTS ix_raw_items_product_id         ON raw.order_items_raw(product_id);
CREATE INDEX IF NOT EXISTS ix_raw_customers_customer_id    ON raw.customers_raw(customer_id);
CREATE INDEX IF NOT EXISTS ix_raw_payments_order_id        ON raw.payments_raw(order_id);
CREATE INDEX IF NOT EXISTS ix_raw_reviews_review_id        ON raw.reviews_raw(review_id);
CREATE INDEX IF NOT EXISTS ix_raw_sellers_seller_id        ON raw.sellers_raw(seller_id);
-- 지오는 매우 큼(100만+) → 과도한 인덱스는 비추. 필요 시 zip_code_prefix만
CREATE INDEX IF NOT EXISTS ix_raw_geo_zip                  ON raw.geolocation_raw(geolocation_zip_code_prefix);
