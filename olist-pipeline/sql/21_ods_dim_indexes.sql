CREATE INDEX IF NOT EXISTS idx_products_category   ON ods.products(product_category_name);
CREATE INDEX IF NOT EXISTS idx_sellers_state       ON ods.sellers(seller_state);
CREATE INDEX IF NOT EXISTS idx_sellers_zip         ON ods.sellers(seller_zip_code_prefix);
CREATE INDEX IF NOT EXISTS idx_geo_zip             ON ods.geolocation(zip_code_prefix);
CREATE INDEX IF NOT EXISTS idx_translation_english ON ods.product_category_translation(product_category_name_english);
