CREATE INDEX IF NOT EXISTS ix_fact_oi_purchase_ts ON fact.order_item(order_purchase_ts);
CREATE INDEX IF NOT EXISTS ix_fact_oi_seller      ON fact.order_item(seller_id);
CREATE INDEX IF NOT EXISTS ix_fact_oi_product     ON fact.order_item(product_id);
