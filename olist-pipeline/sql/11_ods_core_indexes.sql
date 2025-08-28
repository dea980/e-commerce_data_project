-- orders
CREATE INDEX IF NOT EXISTS idx_orders_customer            ON ods.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status              ON ods.orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_customer  ON ods.orders(delivered_customer_ts);

-- order_items
CREATE INDEX IF NOT EXISTS idx_items_product              ON ods.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller               ON ods.order_items(seller_id);

-- payments
CREATE INDEX IF NOT EXISTS idx_pay_type                   ON ods.payments(payment_type);

-- reviews
CREATE INDEX IF NOT EXISTS idx_reviews_score              ON ods.reviews(review_score);
